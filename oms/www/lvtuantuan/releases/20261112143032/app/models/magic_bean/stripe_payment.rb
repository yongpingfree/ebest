# frozen_string_literal: true
module MagicBean
  class StripePayment < Payment
    # concerns

    # scope

    # constants
    REFUND_QUERY_FIRST_TIME = 10.seconds
    REFUND_QUERY_TIME = 3.hours

    # attr related macros
    @@stripe_logger = ::Logger.new("./log/stripe.log")

    # association macros

    # validation macros

    # callbacks

    # other macros

    # instance methods
    def refund!
      @@stripe_logger.info("refund for order: #{order.id}")

      transaction do
        begin
          response = Stripe::Refund.create(payment_intent: parent_transaction_id, amount: amount_in_cent.to_i)

          if response[:status] == "succeeded"
            @@stripe_logger.info("refund for order success: #{id}")
            paymentable.drawback! if paymentable.refunding?
            update(transaction_id: response[:id], response: response, completed_at: Time.zone.at(response[:created]))
            complete!
          else
            update(response: response)
            fail!
            @@stripe_logge.error("#{paymentable_type} - no: #{paymentable.no}; refund result: #{response}")
            raise "退款失败；order_no: #{paymentable.no}"
          end
        rescue Stripe::InvalidRequestError => e
          @@stripe_logger.error("refund for order failure: #{id}, #{e.message}")
        end
      end
    end

    # class methods
    # 非创建paymentIntent的支付数据处理
    def self.find_or_create_charge_from_webhook(paymentable, data, ebest_channel)
      payment = find_or_initialize_by({
        paymentable: paymentable,
        transaction_id: data[:id],
        amount_in_cent: data[:amount],
        status: :completed,
        payment_type: :charge
      })

      service_amount = payment.amount_in_cent - paymentable.payment_in_cent
      payment.update(response: data, completed_at: Time.zone.at(data[:created]), channel: ebest_channel,
                     service_amount_in_cent: service_amount)

      paymentable.set_order_items_service_amount(service_amount)

      paymentable.update_columns(final_amount_in_cent: payment.amount_in_cent)
      payment
    end

    # 创建paymentIntent的支付数据处理
    def self.find_or_create_charge_from_intent_webhook(paymentable, data, ebest_channel = "app")
      trade_amount_in_cent = data["amount"].to_i  # data["amount"]单位是分
      payment = find_or_initialize_by({
                                        paymentable: paymentable,
                                        transaction_id: data["id"],
                                        amount_in_cent: trade_amount_in_cent,
                                        status: :completed,
                                        payment_type: :charge,
                                        channel: ebest_channel
                                      })
      @@stripe_logger.info("create payment for order: #{paymentable.id}, result: #{data}")
      service_amount = payment.amount_in_cent - paymentable.payment_in_cent
      credit_card_percentage = (service_amount * 100 / paymentable.payment_in_cent.to_f).round(2)

      payment.update(
        response: data,
        completed_at: Time.zone.at(data["created"].to_i),
        service_amount_in_cent: service_amount
      )

      paymentable.set_order_items_service_amount(service_amount)

      paymentable.update(        
        final_amount_in_cent: payment.amount_in_cent,
        actual_credit_card_service_percentage: credit_card_percentage,
        actual_credit_card_service_amount_in_cent: service_amount
      )

      payment
    end

    # 支付金额 - 正在退款金额 - 已退款金额 - 手续费 - 运费 - 上楼服务费
    # 单位由 payment type 决定, 此类中为 $
    def can_refund_amount(refund_freight = false, refund_service_amount = false, refund_box_regulation_fee = false, refund_package_service_fee = false)
      super
    end

    def order_payment_mode
      "stripe_credit_card"
    end

    # private methods
  end
end
