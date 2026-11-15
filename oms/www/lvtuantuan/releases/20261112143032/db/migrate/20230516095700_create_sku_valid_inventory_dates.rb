# frozen_string_literal: true

class CreateSkuValidInventoryDates < ActiveRecord::Migration[5.2]

  def change
    create_table :sku_valid_inventory_dates do |t|

      t.belongs_to :stock_keeping_unit, index: true
      t.date :date, null: false
      t.belongs_to :store, index: true
      t.timestamps
    end
  end
end
