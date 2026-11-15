# frozen_string_literal: true

class MagicBean::Order
  # Klaviyo Email 相关
  module SendgridEmail
    extend ActiveSupport::Concern

    # email_type: paid_order/fulfilled_order/sellout_refunded_order
    def enqueue_send_sendgrid_email_job(email_type)
      SendSendgridEmailJob.perform_later(self.class.model_name.name, id, email_type)
    end
  end
end
