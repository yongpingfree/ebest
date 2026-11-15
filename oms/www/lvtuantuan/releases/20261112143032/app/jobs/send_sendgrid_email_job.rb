# frozen_string_literal: true

class SendSendgridEmailJob < ApplicationJob
  queue_as :sendgrid

  def perform(model_name, id, email_type)
    return if Rails.env.test? || Rails.env.development?

    record = model_name.constantize.find_by id: id
    return if record.nil?

    to_email = record.user_member.email
    return if to_email.blank?

    sendgrid_config = Rails.application.credentials.dig(Rails.env.to_sym, :sendgrid)

    data = {
      personalizations: [
        {
          to: [
            {
              email: to_email
            }
          ],
          dynamic_template_data: BeansApp::API::Entities::Order.represent(record).as_json
        }
      ],
      from: {
        email: sendgrid_config[:from_email]
      },
      template_id: sendgrid_config["#{email_type}_template_id".to_sym]
    }

    SendGridApi.client.mail._('send').post(request_body: data.to_json)
  end
end
