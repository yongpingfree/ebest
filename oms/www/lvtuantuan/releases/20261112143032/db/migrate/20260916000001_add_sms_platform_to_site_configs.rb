# frozen_string_literal: true

class AddSmsPlatformToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :sms_platform, :string, default: "nxcloud", null: false, comment: "短信发送平台"
  end
end
