# frozen_string_literal: true

class SmsSendMessageJob < ApplicationJob
  queue_as :deliver_sms

  def perform(mobile, message, url)
    return if message.blank? || mobile.blank?

    case MagicBean::SiteConfig.default_config.sms_platform
    when "aws"
      Aws::SMS.send_message(Phony.normalize(mobile), message)
    else
      Nxcloud::SMS.send_message(Phony.normalize(mobile), message)
    end

    # begin
    #   android_sms_send_message(Phony.normalize(mobile), message, url)
    # rescue => e
    #   Aliyun::SMS.send_message(Phony.normalize(mobile), message)
    #   OrderMailer.with(mobile: mobile, message: message, fail_message: e.message).android_sms_fail.deliver_later if url.present?
    # end
  end

  private
  def android_sms_send_message(phone, message, url)
    phone_encode = URI.encode(phone, /\W/)
    message_encode = URI.encode(message, /\W/)
    path = "#{url}/sendsms?phone=#{phone_encode}&text=#{message_encode}&password="
    RestClient.get(path, timeout: 20)
  end
end
