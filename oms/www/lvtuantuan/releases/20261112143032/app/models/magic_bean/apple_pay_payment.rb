# frozen_string_literal: true
module MagicBean
  class ApplePayPayment < Payment
    # concerns

    # scope

    # constants
    # 银联服务器在香港，返回时间为香港时间
    TIME_ZONE = "Beijing"

    # attr related macros
    @@apple_pay_logger = ::Logger.new("./log/apple_pay.log")

    # association macros

    # validation macros

    # callbacks

    # other macros

    # instance methods
    def refund!
      @@apple_pay_logger.info("refund for order: #{order.id}")

      transaction do
        options = {
          orderTime: Time.use_zone(TIME_ZONE) { Time.current }.strftime("%Y%m%d%H%M%S"),
          orderCurrency: "036", # AUD - 036
          orderNumber: self.no,
          customerIp: "",
          orderAmount: amount_in_cent.to_i,
          transType: ApplePay::Payment::TRANS_TYPE[:refund],
          origQid: order.completed_charge_payment.transaction_id
        }

        resp = ApplePay::Payment.transaction(options)
        if resp.present? && resp["respCode"] == "00"
          update(
            transaction_id: resp["qid"],
            response: resp
          )
          ApplePayOrderQueryJob.perform_later(id)
        else
          update(response: resp)
          raise "退款失败；payment no: #{self.no}, order no: #{order.no}, result: #{resp}"
        end
      end
    end

    # class methods
    # 1. 银联支付不会立即返回支付结果，所以只先记录返回结果，不做状态变更
    # 2. backend notify 回来的如果code = "00" 则为支付成功
    def self.find_or_create_charge_from_webhook(paymentable, data, ebest_channel)
      payment = find_or_initialize_by({
                                        paymentable: paymentable,
                                        transaction_id: data["qid"],
                                        payment_type: :charge,
                                        status: :pending
                                      })

      payment.update(
        channel: ebest_channel || payment.channel,
        response: data,
        amount_in_cent: data["orderAmount"]
      )
      paymentable.update_columns(final_amount_in_cent: payment.amount_in_cent)

      ApplePayOrderQueryJob.set(wait: 0.1.seconds).perform_later(payment.id)
      payment
    end

    def query
      trans_type, order_number = charge_payment_type? ? [ApplePay::Payment::TRANS_TYPE[:purchase], paymentable.no] : [ApplePay::Payment::TRANS_TYPE[:refund], self.no]

      options = {
        charset: ApplePay::Payment::CHARTSET, #字符编码
        merId: ApplePay::Payment::MER_ID,
        orderNumber: order_number,
        orderTime: Time.use_zone(TIME_ZONE) { Time.current }.strftime("%Y%m%d%H%M%S"),
        transType: trans_type,
        version: ApplePay::Payment::VERSION,
      }

      query_body = ApplePay::Payment.create_back_str_for_back_trans(options)
      resp = ApplePay::Payment.query_order(query_body)

      result_code = resp["queryResult"]
      # respCode返回00才为查询成功
      if !resp["respCode"]&.eql?("00") && result_code.blank?
        ApplePayOrderQueryJob.perform_later(id)
        return
      end

      # 0  Successful.   Accept the transaction
      # 1  Failed.   Reject the transaction
      # 2  Being processed.   Inquire about the transaction later or reject the transaction
      # 3  No such transaction.   Reject the transaction
      case result_code
      when "0"
        # 更新自身信息
        trace_time = resp["traceTime"]
        trace_time = trace_time.present? ? "#{Date.current.year}#{trace_time}".in_time_zone(TIME_ZONE) : Time.current # resp["traceTime"] = "0514114847"
        update(
          transaction_id: resp["qid"],
          response: resp,
          completed_at: trace_time
        )
        self.perform_aasm_event(:complete)

        # 处理订单或售后状态
        if self.charge_payment_type?
          service_amount = amount_in_cent - paymentable.payment_in_cent
          self.update(service_amount_in_cent: service_amount)
          paymentable.set_order_items_service_amount(service_amount)
          paymentable.update_columns(actual_credit_card_service_amount_in_cent:  service_amount)
          paymentable.pay_success(
            resp["qid"],
            trace_time
          )
        elsif self.refund_payment_type?
          paymentable.drawback! if paymentable.refunding?
        end
      when "1", "3"
        update(response: resp)
        self.charge_payment_type? ? paymentable.send(:regenerate_order_no) : self.send(:regenerate_no)
        self.perform_aasm_event(:fail)
        raise "退款失败；payment no: #{self.no}, order no: #{order.no}" if self.refund_payment_type?
      when "2"
        ApplePayOrderQueryJob.perform_later(id)
        update(response: resp)
      end
    end

    # 支付金额 - 正在退款金额 - 已退款金额 - 手续费 - 运费 - 上楼服务费
    # 单位由 payment type 决定, 此类中为 $
    def can_refund_amount(refund_freight = false, refund_service_amount = false, refund_box_regulation_fee = false, refund_package_service_fee = false)
      super
    end

    def order_payment_mode
      "apple_pay"
    end
    # private methods
  end
end
