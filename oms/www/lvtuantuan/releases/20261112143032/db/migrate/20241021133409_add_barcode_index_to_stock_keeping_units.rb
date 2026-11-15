# frozen_string_literal: true

class AddBarcodeIndexToStockKeepingUnits < ActiveRecord::Migration[5.2]
  def change
    add_index :stock_keeping_units, [:barcode, :store_id], unique: true
  end
end
