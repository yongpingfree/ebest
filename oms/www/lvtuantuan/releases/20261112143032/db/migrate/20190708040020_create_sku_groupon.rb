# frozen_string_literal: true

class CreateSkuGroupon < ActiveRecord::Migration[5.2]
  def change
    create_table :sku_groupons do |t|
      t.belongs_to :stock_keeping_unit
      t.belongs_to :groupon_activity
      t.belongs_to :item
      t.integer :price_in_cent, comment: "商品拼团价格"

      t.timestamps
    end

    add_index :sku_groupons,
      %i(groupon_activity_id stock_keeping_unit_id),
      name: "index_sku_groupons_on_groupon_activity_and_stock_keeping_unit",
      unique: true
  end
end
