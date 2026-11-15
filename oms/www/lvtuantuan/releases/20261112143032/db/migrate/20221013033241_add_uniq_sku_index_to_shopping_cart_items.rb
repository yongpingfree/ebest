 # frozen_string_literal: true

class AddUniqSkuIndexToShoppingCartItems < ActiveRecord::Migration[5.2]
  def change
    add_index :shopping_cart_items, [:shopping_cart_id, :stock_keeping_unit_id], unique: true, name: "index_cart_items_on_shopping_cart_id_and_sku_id"
  end
end
