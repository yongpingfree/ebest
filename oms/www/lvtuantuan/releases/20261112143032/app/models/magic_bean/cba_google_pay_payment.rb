# frozen_string_literal: true
module MagicBean
  class CBAGooglePayPayment < Payment
    # concerns
    include MagicBean::CommwebPayment::PaymentConcern

    # callbacks
    after_create :enqueue_check_commweb_paid_job, if: :charge_payment_type?

    # GooglePay和ApplePay需要比较及时响应，执行时间设置为10秒
    def enqueue_check_commweb_paid_job
      CheckCommwebPaidJob.set(wait: 10.second).perform_later(id, self.class.name)
    end

    def order_payment_mode
      "cba_google_pay"
    end
  end
end
