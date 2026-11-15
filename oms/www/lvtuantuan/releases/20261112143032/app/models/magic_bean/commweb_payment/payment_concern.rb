# frozen_string_literal: true

class MagicBean::CommwebPayment
  # CommWeb payment 相关
  module PaymentConcern
    extend ActiveSupport::Concern
    @@commweb_logger = ::Logger.new("./log/commweb.log")
    @@cba_apple_pay_logger = ::Logger.new("./log/cba_apple_pay.log")
    @@cba_google_pay_logger = ::Logger.new("./log/cba_google_pay.log")

    class_methods do
      def find_or_create_charge_from_webhook(paymentable, data, ebest_channel)
        payment = find_or_initialize_by({
                                          paymentable: paymentable,
                                          transaction_id: data["transaction"]["id"],
                                          amount_in_cent: (data["order"]["amount"] * 100).round, # data 中为元
                                          status: :completed,
                                          payment_type: :charge
                                        })

        service_amount = payment.amount_in_cent - paymentable.payment_in_cent
        credit_card_percentage = (service_amount * 100 / paymentable.payment_in_cent.to_f).round(2)

        payment.update(
          channel: ebest_channel,
          response: data,
          completed_at: data["order"]["creationTime"].in_time_zone(self::TIME_ZONE),
          service_amount_in_cent: service_amount
        )

        paymentable.set_order_items_service_amount(service_amount)

        paymentable.update_columns(final_amount_in_cent: payment.amount_in_cent,
                                   actual_credit_card_service_percentage: credit_card_percentage,
                                   actual_credit_card_service_amount_in_cent: service_amount)
        payment
      end
    end

    def refund!
      return if completed?
      logger = custom_logger(object_entity)

      logger.info("refund for order: #{order.id}")

      options = {
        order: {
          id: order.no,
          transaction_id: paymentable.refund_no
        },
        apiOperation: "REFUND",
        transaction: {
          amount: amount_in_cent / 100.0,
          currency: "AUD"
        }
      }

      response = "Commweb::#{target_api_name(object_entity)}".constantize.transaction(options, channel)

      if response["result"] == "SUCCESS"
        logger.info("refund for order success: #{id}")
        transaction do
          paymentable.drawback! if paymentable.refunding?
          update(
            transaction_id: response["transaction"]["id"],
            response: response,
            completed_at: response["order"]["creationTime"].in_time_zone(self.class::TIME_ZONE)
          )
          complete!
        end
      else
        update(response: response)

        logger.error("#{paymentable_type} - no: #{paymentable.refund_no}; refund result: #{response}")
        raise "退款失败；refund_no: #{paymentable.refund_no}, order no: #{order.no}"
      end
    end

    # 如果是待支付就每一分钟检查一次，如果是风险支付就每隔10分钟检查是否审核通过
    def enqueue_check_commweb_paid_job
      wait_time = paymentable.risk_pay? ? 10.minutes : 1.minutes
      CheckCommwebPaidJob.set(wait: wait_time).perform_later(id, self.class.name)
    end

    def check_commweb_payment_paid
      resp = "Commweb::#{target_api_name(object_entity)}".constantize.retrieve_order(paymentable.no, channel)

      risk_resp = resp["risk"]
      if paymentable.risk_pay_enabled && risk_resp.present? && risk_resp["response"]["gatewayCode"] == "REVIEW_REQUIRED" && risk_resp["response"]["review"]["decision"].upcase != "ACCEPTED"
        if risk_resp["response"]["review"]["decision"].upcase == "PENDING"
          # 等待审核
          paymentable.risk! if paymentable.wait_buyer_pay?
          # 风险支付超时通知管理员，不退款
          ::OrderMailer.with(order_no: paymentable.no).order_close_before_cba_risk_callback.deliver_later if paymentable.trade_closed?

          false
        else
          # 审核不通过
          paymentable.close!
          true
        end
      else
        if resp["status"] == "CAPTURED" || resp["status"] == "AUTHORIZED"
          total_captured_amount_in_cent = (resp["totalCapturedAmount"] * 100).round # 计算手续费后的总价
          net_amount_in_cent = paymentable.payment_in_cent # 没计算手续费前的总价
          service_amount_in_cent = total_captured_amount_in_cent - net_amount_in_cent
          credit_card_percentage = (service_amount_in_cent * 100 / net_amount_in_cent.to_f).round(2)
          ActiveRecord::Base.transaction do
            update!(
              response: resp,
              status: :completed,
              service_amount_in_cent: service_amount_in_cent,
              amount_in_cent: total_captured_amount_in_cent,
              completed_at: resp["lastUpdatedTime"].in_time_zone(self.class::TIME_ZONE)
            )

            paymentable.set_order_items_service_amount(service_amount_in_cent)

            if paymentable.trade_closed?
              ::OrderMailer.with(order_no: paymentable.no).order_close_before_cba_callback.deliver_later
              # 触发退款，已经退款的payment不再重复触发
              self.generate_refund_payment(total_captured_amount_in_cent, paymentable, true, true, true, true) unless payments.refund_payment_type.exists?
            else
              paymentable.pay!
            end

            paymentable.update!(paid_at: completed_at, final_amount_in_cent: total_captured_amount_in_cent,
                                credit_card_payment_in_cent: total_captured_amount_in_cent,
                                actual_credit_card_service_percentage: credit_card_percentage,
                                actual_credit_card_service_amount_in_cent: service_amount_in_cent)
          end

          true
        else
          false
        end
      end
    end

    # 专用于处理支付成功但订单还是退款中的数据
    def query_refund_when_no_callback(transaction_id)
      return if transaction_id.blank? || completed?
      order_no = paymentable_type == "MagicBean::AfterSale" ? paymentable.order_no : paymentable.no
      response = "Commweb::#{target_api_name(object_entity)}".constantize.retrieve_transaction(order_no, transaction_id, channel)
      if response["result"] == "SUCCESS"
        transaction do
          paymentable.drawback! if paymentable.refunding?
          update(
            transaction_id: response["transaction"]["id"],
            response: response,
            completed_at: response["order"]["creationTime"].in_time_zone(self.class::TIME_ZONE)
          )
          complete!
        end
      end
    end

    # 支付金额 - 正在退款金额 - 已退款金额 - 手续费 - 运费 - 上楼服务费
    # 单位由 payment type 决定, 此类中为 $
    def can_refund_amount(refund_freight = false, refund_service_amount = false, refund_box_regulation_fee = false, refund_package_service_fee = false)
      super
    end

    def order_payment_mode
      "credit_card"
    end

    def object_entity
      type.gsub("MagicBean::", "")
    end

    def target_api_name(entity)
      case entity
      when "CommwebPayment"
        "Payment"
      when "CBAApplePayPayment", "CBAGooglePayPayment"
        "ApplePay"
      end
    end

    def custom_logger(entity)
      case entity
      when "CommwebPayment"
        @@commweb_logger
      when "CBAApplePayPayment"
        @@cba_apple_pay_logger
      when "CBAGooglePayPayment"
        @@cba_google_pay_logger
      end
    end
  end
end
