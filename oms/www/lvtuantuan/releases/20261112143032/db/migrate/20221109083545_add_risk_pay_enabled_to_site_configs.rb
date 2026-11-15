# frozen_string_literal: true

class AddRiskPayEnabledToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :risk_pay_enabled, :boolean, default: false
  end
end
