class AddCustomListIdToShoppingCartItems < ActiveRecord::Migration[5.2]
  def change
    add_column :shopping_cart_items, :source_custom_list_id, :integer
    add_column :shopping_cart_items, :source_extra_hash, :json
    add_column :order_items, :source_custom_list_id, :integer
    add_column :order_items, :source_extra_hash, :json

    remove_column :shopping_cart_items, :source_page_type
    remove_column :shopping_cart_items, :source_page_id
    remove_column :order_items, :source_page_type
    remove_column :order_items, :source_page_id

    add_index :shopping_cart_items, :source_custom_list_id
    add_index :order_items, :source_custom_list_id
  end
end
