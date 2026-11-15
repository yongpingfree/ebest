# frozen_string_literal: true

class AddOrderPackageSettingsToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :order_package_settings, :jsonb, default: {}
  end
end
