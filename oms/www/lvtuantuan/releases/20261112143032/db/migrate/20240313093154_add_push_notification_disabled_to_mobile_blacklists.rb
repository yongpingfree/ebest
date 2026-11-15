# frozen_string_literal: true

class AddPushNotificationDisabledToMobileBlacklists < ActiveRecord::Migration[5.2]
  def change
    add_column :mobile_blacklists, :push_notification_disabled, :boolean, default: false, comment: "不可接收推送通知"
    add_column :mobile_blacklists, :marketing_sms_disabled, :boolean, default: false, comment: "不可接收营销短信"
  end
end
