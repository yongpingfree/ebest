# frozen_string_literal: true

class AliyunPushNotificationJob < ApplicationJob
  queue_as :push_notification

  def perform(target_value, title, body, ext_parameters = nil)
    push_target_value = (target_value.is_a?(Array) ? target_value : [target_value]).map { |value| "#{Rails.env}_#{value}" }.join(",")

    Aliyun::Push.push_notice_to("ACCOUNT", push_target_value, title, body, ext_parameters)
  end
end
