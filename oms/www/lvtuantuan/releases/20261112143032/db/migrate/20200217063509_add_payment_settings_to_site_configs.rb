# frozen_string_literal: true

class AddPaymentSettingsToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :payment_settings, :json, default: {}
  end
end
