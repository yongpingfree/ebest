# frozen_string_literal: true

class AddGmvAndGpSkuLevels < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :gmv_sku_level, :string
    add_column :stock_keeping_units, :gp_sku_level, :string
  end
end
