# frozen_string_literal: true

class MagicBean::Order
  module Supay
    extend ActiveSupport::Concern

    def supay_callback_too_late_rehandle(pay_data, payment)
      ActiveRecord::Base.transaction do
        update({
                 transaction_id: payment.transaction_id,
                 paid_at: Time.zone.at(pay_data["tradeDate"].to_i),
                 payment_in_progress: false
               })
        pay_when_order_closed
      end
    end

    # 该方法仅用于订单关闭时检查订单状态
    def no_callback_supay_order_rehandle
      close! unless supay_order_handle
    end

    def supay_order_handle
      result = ::Supay::Api.get_order(no)
      ::Supay::Api.logger.info("supay order handle, result is #{result}, order id is #{id}")
      if result["status"] == "T" && result["data"].present? && result["data"]["result"]
        pay_data = JSON.parse(result["data"]["pay_info"]).first
        # 未调起支付的话，这里得到的pay_data为空
        if pay_data.present? && pay_data["tradeStatus"].in?(["TRADE_SUCCESS", "TRADE_FINISHED"])
          supay_success_handle(pay_data)
          return true
        end
      end

      # 如果没支付, 更新payment_in_progress为false
      self.update_columns(payment_in_progress: false)

      false
    end

    # 该方法仅用于轮询检查订单状态
    def check_supay_order_paid
      return unless wait_buyer_pay?

      result = ::Supay::Api.get_order(no)
      ::Supay::Api.logger.info("check supay order paid, result is #{result}, order id is #{id}")

      # 如果还没支付，则下一分钟再查
      if result["status"] == "T" && result["data"].present? && result["data"]["result"]
        pay_data = JSON.parse(result["data"]["pay_info"]).first
        # 未调起支付的话，这里得到的pay_data为空
        if pay_data.present? && pay_data["tradeStatus"] == "WAIT_BUYER_PAY"
          enqueue_check_supay_paid_job
        elsif pay_data["tradeStatus"].in?(["TRADE_SUCCESS", "TRADE_FINISHED"])
          supay_success_handle(pay_data)
        else
          self.update_columns(payment_in_progress: false)
        end
      else
        enqueue_check_supay_paid_job
      end
    end

    # 这个方法仅用于支付前检查订单是否已经支付过，避免重复支付
    def check_supay_order_paid_by_order_no(channel)
      return { error_msg: I18n.t("error.order.order_closed_notice") } if trade_closed?
      return { error_msg: I18n.t("error.order.order_already_paid") } unless wait_buyer_pay?

      result = ::Supay::Api.get_order(no)
      ::Supay::Api.logger.info("check supay order paid by no, result is #{result}, order id is #{id}")

      if result["status"] == "T" && result["data"].present? && result["data"]["result"]
        pay_data = JSON.parse(result["data"]["pay_info"]).first
        # 未调起支付的话，这里得到的pay_data为空
        if pay_data.present? && pay_data["tradeStatus"].in?(["TRADE_SUCCESS", "TRADE_FINISHED"])
          supay_success_handle(pay_data, channel)
          return { error_msg: I18n.t("error.order.order_already_paid") }
        end
      end

      {}
    end

    def enqueue_check_supay_paid_job
      CheckSupayPaidJob.set(wait: 1.minute).perform_later(id)
    end

    def supay_wechat_service_percentage
      order_payment_setting.supay_wechat_service_percentage
    end

    def supay_alipay_service_percentage
      order_payment_setting.supay_alipay_service_percentage
    end

    def supay_wechat_service_amount_dollar_in_cent
      (payment_in_cent * supay_wechat_service_percentage.to_f / 100.0).ceil
    end

    def supay_alipay_service_amount_dollar_in_cent
      (payment_in_cent * supay_alipay_service_percentage.to_f / 100.0).ceil
    end

    # supay采用进一法计算
    def supay_wechat_payment_dollar_in_cent
      if no_transaction_fee?
        payment_in_cent
      else
        (payment_in_cent * (1 + supay_wechat_service_percentage.to_f / 100.0).round(4)).round(2).ceil
      end
    end

    def supay_wechat_payment_in_cent
      (supay_wechat_payment_dollar_in_cent * aud_to_cny_exchange_rate).round
    end

    def supay_alipay_payment_dollar_in_cent
      if no_transaction_fee?
        payment_in_cent
      else
        (payment_in_cent * (1 + supay_alipay_service_percentage.to_f / 100.0).round(4)).round(2).ceil
      end
    end

    def supay_alipay_payment_in_cent
      (supay_alipay_payment_dollar_in_cent * aud_to_cny_exchange_rate).round
    end

    def supay_service_amount_in_cent
      (supay_service_amount_dollar_in_cent * aud_to_cny_exchange_rate).round
    end

    # 仅用于支付时计算是否要加手术费
    def supay_pay_amount_in_yuan(platform)
      if no_transaction_fee?
        payment_in_yuan
      else
        platform == MagicBean::SupayPayment::WECHAT_PLATFORM ? supay_wechat_payment_dollar_in_yuan : supay_alipay_payment_dollar_in_yuan
      end
    end

    private
    def supay_success_handle(pay_data, channel = "app")
      payment = MagicBean::SupayPayment.find_or_create_charge_from_webhook(self, pay_data, channel)

      if trade_closed?
        ::OrderMailer.with(order_no: no).order_close_before_supay_callback.deliver_later
        # 触发退款，已经退款的payment不再重复触发
        payment.generate_refund_payment(payment.amount_in_cent, self, true, true, true, true) unless payment.payments.refund_payment_type.exists?
      else
        pay_success(
          payment.transaction_id,
          Time.zone.at(pay_data["tradeDate"].to_i)
        )
      end
    end
  end
end
