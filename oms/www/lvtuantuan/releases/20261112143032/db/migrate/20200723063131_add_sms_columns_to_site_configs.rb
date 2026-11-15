# frozen_string_literal: true

class AddSmsColumnsToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :config_type, :integer, default: 1
    add_column :site_configs, :sms_first_phone_send_at, :datetime
    add_column :site_configs, :sms_second_phone_send_at, :datetime

    say_with_time "init_sms_site_config" do
      MagicBean::SiteConfig.reset_column_information
      MagicBean::SiteConfig.new(config_type: 2, sms_first_phone_send_at: Time.current, sms_second_phone_send_at: Time.current).save(validate: false)
    end
  end
end
