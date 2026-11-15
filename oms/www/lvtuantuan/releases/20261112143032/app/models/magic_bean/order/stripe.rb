# frozen_string_literal: true

class MagicBean::Order
  module Stripe
    extend ActiveSupport::Concern

    def stripe_callback_too_late_rehandle(pay_data, payment)
      ActiveRecord::Base.transaction do
        update({
                 transaction_id: payment.transaction_id,
                 paid_at: Time.zone.at(pay_data["created"].to_i),
                 payment_in_progress: false
               })
        pay_when_order_closed
      end
    end

    # 该方法仅用于订单关闭时检查订单状态
    def no_callback_stripe_order_rehandle
      result = ::Stripe::PaymentIntent.retrieve(stripe_transaction_id)
      if result["status"] == "succeeded"       
        stripe_success_handle(result, channel)
      else
        self.update_columns(payment_in_progress: false)
        close!
      end
    end

    # 该方法仅用于轮询检查订单状态
    def check_stripe_order_paid
      return unless wait_buyer_pay?
      result = ::Stripe::PaymentIntent.retrieve(stripe_transaction_id)

      if result["status"] == "succeeded"
        stripe_success_handle(result, channel)
      else
        enqueue_check_stripe_paid_job
      end
    end

    # 这个方法仅用于支付前检查订单是否已经支付过，避免重复支付
    def check_stripe_order_paid_by_order_no(channel)
      return { error_msg: I18n.t("error.order.order_closed_notice") } if trade_closed?
      return { error_msg: I18n.t("error.order.order_already_paid") } unless wait_buyer_pay?
      return {} unless stripe_transaction_id?

      result = ::Stripe::PaymentIntent.retrieve(stripe_transaction_id)

      if result["status"] == "succeeded"       
        stripe_success_handle(result, channel)
        return { error_msg: I18n.t("error.order.order_already_paid") }
      end

      {}
    end

    def enqueue_check_stripe_paid_job
      CheckStripePaidJob.set(wait: 1.minute).perform_later(id)
    end

    def stripe_credit_card_service_percentage
      order_payment_setting.stripe_credit_card_service_percentage
    end

    def stripe_apple_pay_service_percentage
      order_payment_setting.stripe_apple_pay_service_percentage
    end

    def stripe_google_pay_service_percentage
      order_payment_setting.stripe_google_pay_service_percentage
    end

    # stripe采用进一法计算
    def stripe_credit_card_payment_in_cent
      if no_transaction_fee?
        payment_in_cent
      else
        (payment_in_cent * (1 + stripe_credit_card_service_percentage.to_f / 100.0).round(4)).round(2).ceil
      end
    end

    def stripe_google_pay_payment_in_cent
      if no_transaction_fee?
        payment_in_cent
      else
        # 1 + 0.14 = 1.1400000000000001, 所以要手续费百分比保留4位小数后再做计算
        # 1500 * 1.12 = 1680.0000000000002, 所以payment_in_cent乘完之后要先round(2)再ceil
        (payment_in_cent * (1 + stripe_google_pay_service_percentage.to_f / 100.0).round(4)).round(2).ceil
      end
    end    

    def stripe_apple_pay_payment_in_cent
      if no_transaction_fee?
        payment_in_cent
      else
        (payment_in_cent * (1 + stripe_apple_pay_service_percentage.to_f / 100.0).round(4)).round(2).ceil
      end
    end

    def stripe_credit_card_service_amount_in_cent
      (payment_in_cent * stripe_credit_card_service_percentage.to_f / 100.0).ceil
    end

    def stripe_google_pay_service_amount_in_cent
      (payment_in_cent * stripe_google_pay_service_percentage.to_f / 100.0).ceil
    end

    def stripe_apple_pay_service_amount_in_cent
      (payment_in_cent * stripe_apple_pay_service_percentage.to_f / 100.0).ceil
    end

    private
    def stripe_success_handle(pay_data, channel = "app")
      payment_class_name = case pay_data["metadata"]["type"]
        when "google_pay"
          "MagicBean::StripeGooglePayPayment"
        when "apple_pay"
          "MagicBean::StripeApplePayPayment" 
        else
          "MagicBean::StripePayment"
        end

      payment = payment_class_name.constantize.find_or_create_charge_from_intent_webhook(self, pay_data, channel)

      if trade_closed?
        ::OrderMailer.with(order_no: no).order_close_before_stripe_callback.deliver_later
        # 触发退款，已经退款的payment不再重复触发
        payment.generate_refund_payment(payment.amount_in_cent, self, true, true, true, true) unless payment.payments.refund_payment_type.exists?
      else
        pay_success(
          payment.transaction_id,
          Time.zone.at(pay_data.created.to_i)
        )
      end
    end
  end
end
