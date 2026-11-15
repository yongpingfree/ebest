# frozen_string_literal: true

class AddValueAddedServiceSettingsToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :value_added_service_settings, :json, default: {}, comment: "增值服务开关配置"
  end
end
