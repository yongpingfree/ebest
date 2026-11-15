# frozen_string_literal: true

class PushAppNotificationJob < ApplicationJob
  queue_as :push_notification

  def perform(title, message, users = [], extras = {})
    PushNotifier.push(title, message, users, extras)
  rescue JPush::Utils::Exceptions::JPushResponseError
    # 找不到设备无需报异常
  end
end
