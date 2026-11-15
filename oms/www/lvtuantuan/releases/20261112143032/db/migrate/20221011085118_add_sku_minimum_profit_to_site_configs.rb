# frozen_string_literal: true

class AddSkuMinimumProfitToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :sku_minimum_profit_in_cent, :integer
  end
end
