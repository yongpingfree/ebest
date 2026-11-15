# frozen_string_literal: true

class CreateSkuInventorySnapshots < ActiveRecord::Migration[5.2]
  def change
    create_table :sku_inventory_snapshots do |t|

      t.belongs_to :stock_keeping_unit
      t.date :record_date
      t.integer :quantity, default: 0
      t.integer :reserved_quantity, default: 0
      t.timestamps
    end

    add_index :sku_inventory_snapshots, [:stock_keeping_unit_id, :record_date], name: "sku_inventory_snapshots_on_sku_id_and_record_date", unique: true
  end
end
