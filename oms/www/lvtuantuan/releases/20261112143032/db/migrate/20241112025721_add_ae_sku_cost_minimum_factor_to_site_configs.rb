# frozen_string_literal: true

class AddAeSkuCostMinimumFactorToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :ae_sku_cost_minimum_factor, :decimal, default: 1.3, null: false
  end
end
