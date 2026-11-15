# frozen_string_literal: true

class CreateSameDayDeliveryCartItems < ActiveRecord::Migration[5.2]
  def change
    create_table :same_day_delivery_cart_items do |t|

      t.integer :quantity, default: 1
      t.bigint :same_day_delivery_cart_id
      t.bigint :stock_keeping_unit_id
      t.datetime :deleted_at
      t.belongs_to :store
      t.integer :source_page_name
      t.integer :source_channel
      t.integer :source_custom_list_id
      t.json :source_extra_hash
      t.index ["same_day_delivery_cart_id", "stock_keeping_unit_id"], name: "index_same_day_cart_items_on_shopping_cart_id_and_sku_id", unique: true
      t.index ["source_custom_list_id"], name: "index_same_day_cart_items_on_source_custom_list_id"
      t.index ["same_day_delivery_cart_id"], name: "index_same_day_cart_items_on_shopping_cart_id"
      t.index ["stock_keeping_unit_id"], name: "index_same_day_cart_items_on_stock_keeping_unit_id"

      t.timestamps
    end
  end
end
