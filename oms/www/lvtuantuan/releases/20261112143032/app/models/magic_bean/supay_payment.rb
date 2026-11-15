# frozen_string_literal: true
module MagicBean
  class SupayPayment < Payment
    include PriceConvertConcern
    # concerns

    # scope

    # constants
    WECHAT_PLATFORM = "WXPAY"
    ALIPAY_PLATFORM = "ALIPAY"
    PLATFORMS = [WECHAT_PLATFORM, ALIPAY_PLATFORM]

    # attr related macros
    convert_price_to_yuan :amount_in_cent

    @@supay_logger = ::Logger.new("./log/supay.log")

    # class methods
    def self.find_or_create_charge_from_webhook(paymentable, data, ebest_channel)
      # tradeAmount结尾会带AUD，且单位是元，需要处理数据
      trade_amount_in_cent = (data["tradeAmount"].gsub(" AUD", "").to_f * 100).round
      trade_cny_amount_in_cent = (data["cnyAmount"].to_f * 100).round
      payment = find_or_initialize_by({
                                        paymentable: paymentable,
                                        transaction_id: data["innerTradeNo"],
                                        amount_in_cent: trade_amount_in_cent,
                                        status: :completed,
                                        payment_type: :charge,
                                        channel: ebest_channel
                                      })
      @@supay_logger.info("create payment for order: #{paymentable.id}, result: #{data}")
      service_amount = payment.amount_in_cent - paymentable.payment_in_cent
      payment.update(
        response: data,
        completed_at: Time.zone.at(data["tradeDate"].to_i),
        service_amount_in_cent: service_amount
      )

      paymentable.set_order_items_service_amount(service_amount)

      paymentable.update(
        supay_payment_dollar_in_cent: trade_amount_in_cent,
        supay_payment_in_cent: trade_cny_amount_in_cent,
        supay_service_amount_dollar_in_cent: service_amount,
        aud_to_cny_exchange_rate: data["rate"],
        final_amount_in_cent: payment.amount_in_cent
      )

      payment
    end

    # instance methods
    def refund!
      return if completed?

      @@supay_logger.info("refund for order: #{order.id}")

      # 退款金额要传元
      refund_params = {
        service: "create_refund",
        refund_amount: amount_in_yuan,
        mch_order_no: no, # refund_no
        orig_mch_order_no: order.no # order_no
      }

      result = Supay::Api.refund(refund_params)

      # 如果status为false，要检查是否已经退款过了，退款过的回调是{"status"=>"F", "message"=>"220007:transaction refund is success", "data"=>nil}
      if (result["status"].eql?("T") && result["data"].present? && result["data"]["result"]) || (result["status"].eql?("F") && result["message"].include?("220007"))
        paymentable.drawback! if paymentable.refunding?
        complete!
      else
        update(response: result)

        raise "Supay退款失败；payment no: #{self.no}, order no: #{order.no}"
      end
    end

    # 支付金额 - 正在退款金额 - 已退款金额 - 手续费 - 运费 - 上楼服务费
    # 单位由 payment type 决定, 此类中为 $
    def can_refund_amount(refund_freight = false, refund_service_amount = false, refund_box_regulation_fee = false, refund_package_service_fee = false)
      return 0 unless charge_payment_type? && completed?

      return @can_refund_amount if @can_refund_amount

      @can_refund_amount = amount_in_cent - refunding_amount_in_cent - refund_amount_in_cent

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
      "supay"
    end
  end
end
