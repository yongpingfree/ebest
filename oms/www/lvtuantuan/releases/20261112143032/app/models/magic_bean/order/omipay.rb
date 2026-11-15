# frozen_string_literal: true

class MagicBean::Order
  module Omipay
    extend ActiveSupport::Concern

    @@special_logger = ::Logger.new("./log/special_order_error.log")

    def callback_too_late_rehandle(result, payment)
      ActiveRecord::Base.transaction do
        update({
                 transaction_id: payment.transaction_id,
                 paid_at: result["pay_time"].in_time_zone(MagicBean::OmipayPayment::TIME_ZONE),
                 payment_in_progress: false
               })
        pay_when_order_closed
      end
    end

    def no_callback_omipay_order_rehandle
      result = ::Omipay::Api.get_order(omipay_transaction_id)
      ::Omipay::Api.logger.info("omipay order no callback rehandle, result is #{result}, order id is #{id}")
      if result["return_code"] == "SUCCESS" && result["result_code"] == "PAID" && wait_buyer_pay?
        pay_success_handle(result)
      elsif result["return_code"] == "SUCCESS" && result["result_code"] == "PAYING"
        # TODO: 正在支付的暂时不处理，后续有问题再跟进
        ::Omipay::Api.logger.info("order id is #{id}, omipay result_code is PAYING, result is #{result}")
      else
        self.update_columns(payment_in_progress: false)
        close!
      end
    end

    def check_omipay_order_paid
      return unless wait_buyer_pay?

      result = ::Omipay::Api.get_order(omipay_transaction_id)
      ::Omipay::Api.logger.info("check omipay order paid, result is #{result}, order id is #{id}")

      # 如果还没支付，则下一分钟再查
      if result["return_code"] == "SUCCESS" && result["result_code"] == "PAID"
        pay_success_handle(result)
      else
        enqueue_check_omipay_paid_job
      end
    end

    def check_omipay_order_paid_by_order_no(channel)
      return { error_msg: I18n.t("error.order.order_closed_notice") } if trade_closed?
      return { error_msg: I18n.t("error.order.order_already_paid") } unless wait_buyer_pay?

      result = ::Omipay::Api.get_order_by_out_order_no(no)
      ::Omipay::Api.logger.info("check omipay order paid by out_order_no, result is #{result}, order id is #{id}")

      if result["return_code"] == "SUCCESS" && result["result_code"] == "PAID"
        pay_success_handle(result, channel)
        { error_msg: I18n.t("error.order.order_already_paid") }
      else
        {}
      end
    end

    def enqueue_check_omipay_paid_job
      CheckOmipayPaidJob.set(wait: 1.minute).perform_later(id)
    end

    def omipay_wechat_service_percentage
      order_payment_setting.omipay_wechat_service_percentage
    end

    def omipay_alipay_service_percentage
      order_payment_setting.omipay_alipay_service_percentage
    end

    def omipay_wechat_service_amount_dollar_in_cent
      (payment_in_cent * omipay_wechat_service_percentage.to_f / 100.0).ceil
    end

    def omipay_alipay_service_amount_dollar_in_cent
      (payment_in_cent * omipay_alipay_service_percentage.to_f / 100.0).ceil
    end

    # omipay采用进一法计算
    def omipay_wechat_payment_dollar_in_cent
      if no_transaction_fee?
        payment_in_cent
      else
        (payment_in_cent * (1 + omipay_wechat_service_percentage.to_f / 100.0).round(4)).round(2).ceil
      end
    end

    def omipay_wechat_payment_in_cent
      (omipay_wechat_payment_dollar_in_cent * aud_to_cny_exchange_rate).round
    end

    def omipay_alipay_payment_dollar_in_cent
      if no_transaction_fee?
        payment_in_cent
      else
        (payment_in_cent * (1 + omipay_alipay_service_percentage.to_f / 100.0).round(4)).round(2).ceil
      end
    end

    def omipay_alipay_payment_in_cent
      (omipay_alipay_payment_dollar_in_cent * aud_to_cny_exchange_rate).round
    end

    def omipay_service_amount_in_cent
      (omipay_service_amount_dollar_in_cent * aud_to_cny_exchange_rate).round
    end

    # 仅用于支付时计算是否要加手术费
    def omipay_pay_amount_in_cent(platform)
      if no_transaction_fee?
        payment_in_cent
      else
        platform == MagicBean::OmipayPayment::WECHAT_PLATFORM ? omipay_wechat_payment_dollar_in_cent : omipay_alipay_payment_dollar_in_cent
      end
    end

    private
    def pay_success_handle(result, channel = "app")
      payment = MagicBean::OmipayPayment.find_or_create_charge_when_no_callback(self, result, channel)
      pay_success(
        payment.transaction_id,
        result["pay_time"].in_time_zone(MagicBean::OmipayPayment::TIME_ZONE)
      )
    end
  end
end
