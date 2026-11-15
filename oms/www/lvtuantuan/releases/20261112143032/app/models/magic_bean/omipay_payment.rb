# frozen_string_literal: true
module MagicBean
  class OmipayPayment < Payment
    # concerns

    # scope

    # constants
    REFUND_QUERY_FIRST_TIME = 10.seconds
    REFUND_QUERY_TIME = 3.hours
    WECHAT_PLATFORM = "WECHATPAY"
    ALIPAY_PLATFORM = "ALIPAYONLINE"
    PLATFORMS = [WECHAT_PLATFORM, ALIPAY_PLATFORM]

    # attr related macros
    @@omipay_logger = ::Logger.new("./log/omipay.log")

    # class methods
    def self.find_or_create_charge_from_webhook(paymentable, data, ebest_channel)
      payment = find_or_initialize_by({
                                        paymentable: paymentable,
                                        transaction_id: data["order_no"],
                                        amount_in_cent: data["total_amount"], # data 中为分
                                        status: :completed,
                                        payment_type: :charge
                                      })
      @@omipay_logger.info("create payment for order: #{paymentable.id}, result: #{data}")
      service_amount = payment.amount_in_cent - paymentable.payment_in_cent
      payment.update(
        platform: paymentable.omipay_platform,
        channel: ebest_channel,
        response: data,
        completed_at: data["pay_time"].in_time_zone(TIME_ZONE),
        service_amount_in_cent: service_amount
      )

      paymentable.set_order_items_service_amount(service_amount)

      paymentable.update(omipay_payment_dollar_in_cent: data["total_amount"],
                         omipay_payment_in_cent: data["cny_amount"],
                         omipay_service_amount_dollar_in_cent: service_amount,
                         aud_to_cny_exchange_rate: data["exchange_rate"].to_f/(10**8),
                         final_amount_in_cent: payment.amount_in_cent
                         )

      payment
    end

    # 该方法专门用于处理omipay支付成功但没有回调的情况
    def self.find_or_create_charge_when_no_callback(paymentable, data, ebest_channel)
      payment = find_or_initialize_by({
                                        paymentable: paymentable,
                                        transaction_id: paymentable.omipay_transaction_id,
                                        amount_in_cent: data["amount"], # data 中为分
                                        status: :completed,
                                        payment_type: :charge
                                      })
      service_amount = payment.amount_in_cent - paymentable.payment_in_cent
      payment.update(
        platform: paymentable.omipay_platform,
        channel: ebest_channel,
        response: data,
        completed_at: data["pay_time"].in_time_zone(TIME_ZONE),
        service_amount_in_cent: service_amount
      )

      paymentable.set_order_items_service_amount(service_amount)

      paymentable.update(omipay_payment_dollar_in_cent: data["amount"],
                         omipay_payment_in_cent: data["pay_amount"],
                         omipay_service_amount_dollar_in_cent: service_amount,
                         aud_to_cny_exchange_rate: data["exchange_rate"].to_f/(10**8),
                         final_amount_in_cent: payment.amount_in_cent
      )

      payment

    end

    # instance methods
    def refund!
      return if completed?
      return if paymentable_refunded?(paymentable.refund_no)

      @@omipay_logger.info("refund for order: #{order.id}")

      # 金额，货币是订单的下单 货币，单位为订单下单货 币的最小货币值，当前场景最小货币值为分
      result = Omipay::Api.refund(order_no: parent_transaction_id, out_refund_no: paymentable.refund_no, amount: amount_in_cent.to_i)
      if result["return_code"].eql?("SUCCESS")
        update(transaction_id: result["refund_no"], response: result, completed_at: result["refund_time"].in_time_zone(TIME_ZONE))

        RefundQueryJob.set(wait: REFUND_QUERY_FIRST_TIME).perform_later(id)
      else
        update(response: result)

        @@omipay_logger.error("#{paymentable_type} - no: #{paymentable.refund_no}; refund result: #{result}")
        raise "申请退款: #{result["error_msg"] || '退款失败'}; no: #{paymentable.refund_no}, order no: #{order.no}"
      end
    end

    def refund_query
      result = Omipay::Api.refund_query({ refund_no: transaction_id })

      if result["return_code"].eql?("SUCCESS")
        case result["result_code"]
        when "PaymentChannelConfirmed", "OrganizationPayback", "Cleared" # 支付机构已退款
          paymentable.drawback! if paymentable.refunding?
          complete!

          return
        end
      end

      RefundQueryJob.set(wait: REFUND_QUERY_TIME).perform_later(id)
    end

    def refund_query_by_order_no
      return if completed?
      out_order_no = paymentable_type == "MagicBean::AfterSale" ? paymentable.order_no : paymentable.no
      result = Omipay::Api.refund_query({ out_order_no: out_order_no })

      if result["return_code"].eql?("SUCCESS")
        update(response: result, completed_at: result["refund_time"].in_time_zone(TIME_ZONE))

        case result["result_code"]
        when "PaymentChannelConfirmed", "OrganizationPayback", "Cleared" # 支付机构已退款
          paymentable.drawback! if paymentable.refunding?
          complete!
        end
      end
    end

    # 支付金额 - 正在退款金额 - 已退款金额 - 手续费 - 运费 - 上楼服务费
    # 单位由 payment type 决定, 此类中为 $
    def can_refund_amount(refund_freight = false, refund_service_amount = false, refund_box_regulation_fee = false, refund_package_service_fee = false)
      return 0 unless charge_payment_type? && completed?

      return @can_refund_amount if @can_refund_amount

      @can_refund_amount = amount_in_cent - refunding_amount_in_cent - refund_amount_in_cent
      @can_refund_amount -= service_amount_in_cent unless refund_service_amount

      # 售后不退运费和上楼服务费，不退邮费的情况都是不退上楼费的
      unless paymentable_type == "MagicBean::Order" && refund_freight
        @can_refund_amount = @can_refund_amount - order.freight_in_cent - order.deliver_to_door_service_fee_in_cent
      end

      @can_refund_amount -= order.box_regulation_fee_in_cent unless paymentable_type == "MagicBean::Order" && refund_box_regulation_fee
      @can_refund_amount -= order.package_service_fee_in_cent unless paymentable_type == "MagicBean::Order" && refund_package_service_fee

      @can_refund_amount = 0 unless @can_refund_amount.positive?

      @can_refund_amount
    end

    def order_payment_mode
      "omipay"
    end

    def paymentable_refunded?(out_refund_no)
      result = ::Omipay::Api.refund_query({ out_refund_no: out_refund_no })
      ::Omipay::Api.logger.info("check paymentable refunded, out_refund_no is #{out_refund_no}, result is #{result}, ")

      if result["return_code"].eql?("SUCCESS")
        case result["result_code"]
        when "PaymentChannelConfirmed", "OrganizationPayback", "Cleared" # 支付机构已退款

          update(response: result, completed_at: result["refund_time"].in_time_zone(TIME_ZONE))
          paymentable.drawback! if paymentable.refunding?
          complete!

          return true
        end
      end

      false
    end
  end
end
