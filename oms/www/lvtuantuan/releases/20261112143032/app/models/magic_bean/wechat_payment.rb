# frozen_string_literal: true
module MagicBean
  class WechatPayment < Payment
    # concerns

    # scope

    # constants
    REFUND_QUERY_FIRST_TIME = 10.seconds
    REFUND_QUERY_TIME = 3.hours
    TIME_ZONE = "Beijing"

    # attr related macros

    # association macros

    # validation macros

    # callbacks

    # other macros

    # instance methods
    # wechat request refund result
    # {:raw=>
    #   {"xml"=>
    #     {"return_code"=>"SUCCESS",
    #      "return_msg"=>"OK",
    #      "appid"=>"wxd9af63d629e12828",
    #      "mch_id"=>"1391885502",
    #      "nonce_str"=>"e6sd2AszuPvFsEnH",
    #      "sign"=>"D7C425E157042C339EF16791CA28F31A",
    #      "result_code"=>"SUCCESS",
    #      "transaction_id"=>"4200000503202002133506971867",
    #      "out_trade_no"=>"202002131045184524",
    #      "out_refund_no"=>"202002131045184524o",
    #      "refund_id"=>"50000303222020021314697172750",
    #      "refund_channel"=>"",
    #      "refund_fee"=>"1",
    #      "coupon_refund_fee"=>"0",
    #      "total_fee"=>"1",
    #      "cash_fee"=>"1",
    #      "coupon_refund_count"=>"0",
    #      "cash_refund_fee"=>"1"}},
    #  "return_code"=>"SUCCESS",
    #  "return_msg"=>"OK",
    #  "appid"=>"wxd9af63d629e12828",
    #  "mch_id"=>"1391885502",
    #  "nonce_str"=>"e6sd2AszuPvFsEnH",
    #  "sign"=>"D7C425E157042C339EF16791CA28F31A",
    #  "result_code"=>"SUCCESS",
    #  "transaction_id"=>"4200000503202002133506971867",
    #  "out_trade_no"=>"202002131045184524",
    #  "out_refund_no"=>"202002131045184524o",
    #  "refund_id"=>"50000303222020021314697172750",
    #  "refund_channel"=>"",
    #  "refund_fee"=>"1",
    #  "coupon_refund_fee"=>"0",
    #  "total_fee"=>"1",
    #  "cash_fee"=>"1",
    #  "coupon_refund_count"=>"0",
    #  "cash_refund_fee"=>"1"}
    def refund!
      wechat_refund_params = { refund_fee: amount_in_cent.to_i }.reverse_merge(paymentable.wechat_refund_params)
      xml_result = WxPay::Service.invoke_refund(wechat_refund_params)
      WxPay.logger.info("request refund for #{paymentable_type}: #{paymentable.id}, params: #{wechat_refund_params} result: #{xml_result}")
      result = xml_result.dig(:raw, "xml")
      if xml_result.success?
        update(
          transaction_id: result["refund_id"],
          response: result
        )
        RefundQueryJob.set(wait: REFUND_QUERY_FIRST_TIME).perform_later(id)
      else
        update(response: result)
        WxPay.logger.error("#{paymentable_type} - no: #{paymentable.no}; refund result: #{result}")
        raise "微信支付: #{result.dig(:raw, 'xml', 'err_code_des') || '退款失败'}；order_no: #{paymentable.no}"
      end
    end

    # {:raw=>
    #   {"xml"=>
    #     {"appid"=>"wxd9af63d629e12828",
    #      "cash_fee"=>"1",
    #      "mch_id"=>"1391885502",
    #      "nonce_str"=>"eDs5RaoRYkHFC9w0",
    #      "out_refund_no_0"=>"202002131045184524o",
    #      "out_trade_no"=>"202002131045184524",
    #      "refund_account_0"=>"REFUND_SOURCE_UNSETTLED_FUNDS",
    #      "refund_channel_0"=>"ORIGINAL",
    #      "refund_count"=>"1",
    #      "refund_fee"=>"1",
    #      "refund_fee_0"=>"1",
    #      "refund_id_0"=>"50000303222020021314697172750",
    #      "refund_recv_accout_0"=>"支付用户的零钱",
    #      "refund_status_0"=>"SUCCESS",
    #      "refund_success_time_0"=>"2020-02-13 16:04:32",
    #      "result_code"=>"SUCCESS",
    #      "return_code"=>"SUCCESS",
    #      "return_msg"=>"OK",
    #      "sign"=>"773F9878DBABFB4C1B1E46D08CD1FE42",
    #      "total_fee"=>"1",
    #      "transaction_id"=>"4200000503202002133506971867"}},
    #  "appid"=>"wxd9af63d629e12828",
    #  "cash_fee"=>"1",
    #  "mch_id"=>"1391885502",
    #  "nonce_str"=>"eDs5RaoRYkHFC9w0",
    #  "out_refund_no_0"=>"202002131045184524o",
    #  "out_trade_no"=>"202002131045184524",
    #  "refund_account_0"=>"REFUND_SOURCE_UNSETTLED_FUNDS",
    #  "refund_channel_0"=>"ORIGINAL",
    #  "refund_count"=>"1",
    #  "refund_fee"=>"1",
    #  "refund_fee_0"=>"1",
    #  "refund_id_0"=>"50000303222020021314697172750",
    #  "refund_recv_accout_0"=>"支付用户的零钱",
    #  "refund_status_0"=>"SUCCESS",
    #  "refund_success_time_0"=>"2020-02-13 16:04:32",
    #  "result_code"=>"SUCCESS",
    #  "return_code"=>"SUCCESS",
    #  "return_msg"=>"OK",
    #  "sign"=>"773F9878DBABFB4C1B1E46D08CD1FE42",
    #  "total_fee"=>"1",
    #  "transaction_id"=>"4200000503202002133506971867"}
    def refund_query
      return if completed?
      begin
        result = WxPay::Service.refund_query(transaction_id: transaction_id)
        if result.dig("err_code").present?
          WxPay.logger.error("payment id: #{id}; refund result: #{result}")
        elsif result.success? && result.select { |k, v| k =~ /^refund_status_/ && v != WxPay::Result::SUCCESS_FLAG }.empty?
          paymentable.drawback! if paymentable.refunding?
          complete!
          update(completed_at: result["refund_success_time_0"].in_time_zone(TIME_ZONE))
          return
        end
        RefundQueryJob.set(wait: REFUND_QUERY_TIME).perform_later(id)
      rescue RestClient::Exceptions::Timeout
      end
    end

    # class methods

    # wechat pay result
    # {
    #   "appid"=>"wxd9af63d629e12828",
    #   "bank_type"=>"OTHERS",
    #   "cash_fee"=>"1",
    #   "fee_type"=>"CNY",
    #   "is_subscribe"=>"N",
    #   "mch_id"=>"1391885502",
    #   "nonce_str"=>"69297beccb064629b091712c3c85e4c7",
    #   "openid"=>"oeXda5JCqzUERlvBVUUxOEkSOUBU",
    #   "out_trade_no"=>"202002131023650952",
    #   "result_code"=>"SUCCESS",
    #   "return_code"=>"SUCCESS",
    #   "sign"=>"B9DD4B8E0D090744A18009B9E6DDBD0C",
    #   "time_end"=>"20200213102353",
    #   "total_fee"=>"1",
    #   "trade_type"=>"JSAPI",
    #   "transaction_id"=>"4200000507202002132363201679"
    # }
    def self.find_or_create_charge_from_webhook(paymentable, data, ebest_channel = "mini_program")
      payment = find_or_initialize_by({
        paymentable: paymentable,
        transaction_id: data["transaction_id"],
        amount_in_cent: data["total_fee"].to_f,
        status: :completed,
        payment_type: :charge
      })

      service_amount = payment.amount_in_cent - paymentable.wechat_payment_in_cent
      payment.update(
        channel: ebest_channel,
        response: data,
        completed_at: data["time_end"].in_time_zone(TIME_ZONE),
        service_amount_in_cent: service_amount
      )

      paymentable.set_order_items_service_amount(service_amount)

      paymentable.update_columns(final_amount_in_cent: payment.send(:aud_amount_in_cent))
      payment
    end

    # 支付金额 - 正在退款金额 - 已退款金额 - 手续费 - 运费 - 上楼服务费
    # 单位由 payment type 决定, 此类中为 ￥
    def can_refund_amount(refund_freight = false, refund_service_amount = false, refund_box_regulation_fee = false, refund_package_service_fee = false)
      return 0 unless charge_payment_type? && completed?

      return @can_refund_amount if @can_refund_amount

      @can_refund_amount = amount_in_cent - refunding_amount_in_cent - refund_amount_in_cent
      @can_refund_amount -= wechat_service_amount_in_cent unless refund_service_amount
      
      # 售后不退运费和上楼服务费，不退邮费的情况都是不退上楼费的
      unless paymentable_type == "MagicBean::Order" && refund_freight
        @can_refund_amount = @can_refund_amount - order.freight_in_cent - order.deliver_to_door_service_fee_in_cent
      end

      @can_refund_amount -= order.box_regulation_fee_in_cent unless paymentable_type == "MagicBean::Order" && refund_box_regulation_fee
      @can_refund_amount -= order.package_service_fee_in_cent unless paymentable_type == "MagicBean::Order" && refund_package_service_fee
      
      @can_refund_amount = 0 unless @can_refund_amount.positive?

      @can_refund_amount
    end

    def order_rest_payment_in_cent(refund_service_amount = false, refund_box_regulation_fee = false, refund_package_service_fee = false)
      return 0 unless charge_payment_type? && completed?
      cny_to_aud(can_refund_amount(false, refund_service_amount, refund_box_regulation_fee, refund_package_service_fee))
    end

    def generate_refund_payment(wait_to_refund_amount = nil, target_paymentable = nil, refund_freight = false, refund_service_amount = false, refund_box_regulation_fee = false, refund_package_service_fee = false)
      wait_to_refund_amount = (wait_to_refund_amount * order.aud_to_cny_exchange_rate).floor if wait_to_refund_amount
      super
    end

    def order_payment_mode
      "wechat"
    end

    # private methods
    private

    def wechat_service_amount_in_cent
      aud_to_cny(order.wechat_service_amount_in_cent)
    end

    def freight_in_cent
      aud_to_cny(order.freight_in_cent)
    end

    def aud_to_cny(amount)
      (amount * order.aud_to_cny_exchange_rate).ceil(2)
    end

    def cny_to_aud(amount)
      (amount / order.aud_to_cny_exchange_rate).floor(2)
    end

    def aud_amount_in_cent
      cny_to_aud(amount_in_cent)
    end
  end
end
