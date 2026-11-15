# frozen_string_literal: true

class CreateWmsInventories < ActiveRecord::Migration[5.2]
  def change
    # 这个是给 WMS 报表临时存放数据用的，所以不用 timestamps
    create_table :wms_inventories do |t|
      t.integer :store_id
      t.integer :product_id
      t.integer :jerry_sku_id
      t.integer :inventory_type
      t.string :area
      t.string :location
      t.datetime :expiry_date
      t.integer :qty
      t.datetime :updated_at
    end
  end
end
