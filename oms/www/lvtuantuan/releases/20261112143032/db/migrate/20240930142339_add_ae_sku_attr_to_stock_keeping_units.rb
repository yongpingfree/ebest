# frozen_string_literal: true

class AddAeSkuAttrToStockKeepingUnits < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :ae_sku_attr, :string
  end
end
