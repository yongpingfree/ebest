# frozen_string_literal: true

class AddDeliveryTypeSettingsToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :delivery_type_settings, :json, default: {}
  end
end
