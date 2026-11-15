# frozen_string_literal: true

class SmsJob < ApplicationJob
  queue_as :deliver_sms

  def perform(mobile, message)
    # 目前出现了message为true的情况，未找到原因，在发送短信这里做处理
    return if message.blank? || message.to_s == "true" || mobile.blank? || Rails.env.development?

    enqueue_sms_send_message_job(mobile, message)
  end

  private
  def enqueue_sms_send_message_job(mobile, message)
    urls = MagicBean::SiteConfig.default_config.android_sms_public_url&.split(/[;；]/).map(&:strip)
    sms_config = MagicBean::SiteConfig.sms_config
    rand_seconds = rand(5..8)

    @target_url, @perform_time = nil

    sms_config.with_lock do
      @target_url, @perform_time = if urls.size > 1 && sms_config.sms_first_phone_send_at > sms_config.sms_second_phone_send_at
                                     # 手机A发送时间晚于手机B时，使用手机B; 反之使用手机A
                                     sms_send_at = [Time.current, sms_config.sms_second_phone_send_at + rand_seconds.seconds].max
                                     sms_config.update_columns sms_second_phone_send_at: sms_send_at
                                     [urls.second&.gsub(/https:|http:|\//, ""), sms_send_at]
                                   elsif urls.size > 0
                                     sms_send_at = [Time.current, sms_config.sms_first_phone_send_at + rand_seconds.seconds].max
                                     sms_config.update_columns sms_first_phone_send_at: sms_send_at
                                     [urls.first&.gsub(/https:|http:|\//, ""), sms_send_at]
                                   end
    end

    SmsSendMessageJob.set(wait_until: @perform_time).perform_later(mobile, message, @target_url)
  end
end
