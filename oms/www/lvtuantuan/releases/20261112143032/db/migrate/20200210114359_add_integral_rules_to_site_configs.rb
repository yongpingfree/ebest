# frozen_string_literal: true

class AddIntegralRulesToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :integral_rules, :json, default: {}

    remove_column :site_configs, :sign_up_integral, :integer, default: 0
    remove_column :site_configs, :suggest_integral, :integer, default: 0
  end
end
