# frozen_string_literal: true

module MagicBean
  class UnionPayPayment < Payment
    # concerns

    # scope

    # constants
    TIME_ZONE = "Beijing"
    # RESPONSE_CODE_SYS_ERROR = []

    # attr related macros
    @@union_pay_logger = ::Logger.new("./log/union_pay.log")

    # association macros

    # validation macros

    # callbacks

    # other macros

    # instance methods
    def refund!
      @@union_pay_logger.info("refund for order: #{order.id}")

      transaction do
        options = {
          orderTime: Time.use_zone(TIME_ZONE) { Time.current }.strftime("%Y%m%d%H%M%S"),
          orderCurrency: "036", # AUD - 036
          orderNumber: self.no,
          customerIp: "",
          orderAmount: amount_in_cent.to_i,
          transType: UnionPay::Payment::TRANS_TYPE[:refund],
          origQid: order.completed_charge_payment.transaction_id
        }

        resp = UnionPay::Payment.transaction(options)
        if resp.present? && resp["respCode"] == "00"
          update(
            transaction_id: resp["qid"],
            response: resp
          )
          UnionPayQueryJob.perform_later(id)
        else
          update(response: resp)
          raise "退款失败；payment no: #{self.no}, order no: #{order.no}, result: #{resp}"
        end
      end
    end

    def update_and_paymentable_refund(resp)
      resp_code = resp["respCode"]
      trace_time = resp["traceTime"]
      if resp_code == "00"
        @@union_pay_logger.info("refund for order success: #{id}, refund result: #{resp}")
        paymentable.drawback! if paymentable.refunding?
        trace_time = trace_time.present? ? "#{Time.current.in_time_zone(TIME_ZONE).year}#{trace_time}".in_time_zone(TIME_ZONE) : Time.current # resp["traceTime"] = "0514114847"
        update(
          transaction_id: resp["qid"],
          response: resp,
          completed_at: trace_time
        )
        self.perform_aasm_event(:complete)
      else
        update(response: resp)
        regenerate_no
        self.perform_aasm_event(:fail)
        @@union_pay_logger.error("#{paymentable_type} - no: #{self.no}; refund result: #{resp}")
        raise "退款失败；payment no: #{self.no}, order no: #{order.no}"
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
      UnionPayQueryJob.set(wait: 0.1.seconds).perform_later(payment.id)
      payment
    end

    def query
      trans_type = charge_payment_type? ? UnionPay::Payment::TRANS_TYPE[:purchase] : UnionPay::Payment::TRANS_TYPE[:refund]
      order_number = charge_payment_type? ? paymentable.no : self.no
      options = {
        orderNumber: order_number,
        orderTime: Time.use_zone(TIME_ZONE) { Time.current }.strftime("%Y%m%d%H%M%S"),
        transType: trans_type
      }
      resp = UnionPay::Payment.query(options)
      # 返回00才为查询成功
      result_code = resp["queryResult"]

      if !resp["respCode"]&.eql?("00") && result_code.blank?
        UnionPayQueryJob.perform_later(id)
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
        trace_time = trace_time.present? ? "#{ Time.current.in_time_zone("Beijing").year}#{trace_time}".in_time_zone(TIME_ZONE) : Time.current # resp["traceTime"] = "0514114847"
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
          paymentable.update actual_credit_card_service_amount_in_cent: service_amount
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
        UnionPayQueryJob.perform_later(id)
        update(response: resp)
      end
    end

    # 支付金额 - 正在退款金额 - 已退款金额 - 手续费 - 运费 - 上楼服务费
    # 单位由 payment type 决定, 此类中为 $
    def can_refund_amount(refund_freight = false, refund_service_amount = false, refund_box_regulation_fee = false, refund_package_service_fee = false)
      super
    end

    def order_payment_mode
      "union_pay"
    end

    # private methods
  end
end
