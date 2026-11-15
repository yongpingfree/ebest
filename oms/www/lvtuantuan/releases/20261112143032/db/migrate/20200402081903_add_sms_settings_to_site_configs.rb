# frozen_string_literal: true

class AddSmsSettingsToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :android_sms_public_url, :string
    add_column :site_configs, :android_sms_notification_emails, :string, array: true, default: []
  end
end
