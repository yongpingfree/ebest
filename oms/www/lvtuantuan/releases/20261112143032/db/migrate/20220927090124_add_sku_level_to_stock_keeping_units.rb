# frozen_string_literal: true

class AddSkuLevelToStockKeepingUnits < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :sku_level, :string
  end
end
