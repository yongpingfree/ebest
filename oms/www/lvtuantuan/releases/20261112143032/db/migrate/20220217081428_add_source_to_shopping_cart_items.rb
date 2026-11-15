# frozen_string_literal: true

class AddSourceToShoppingCartItems < ActiveRecord::Migration[5.2]
  def change
    add_column :shopping_cart_items, :source_page_name, :integer
    add_column :shopping_cart_items, :source_page_type, :string
    add_column :shopping_cart_items, :source_page_id, :integer
    add_column :shopping_cart_items, :source_channel, :integer
    add_column :order_items, :source_page_name, :integer
    add_belongs_to :order_items, :source_page, polymorphic: true
    add_column :order_items, :source_channel, :integer

    add_index :shopping_cart_items, [:source_page_type, :source_page_id], name: "index_shopping_cart_items_on_source_page"
  end
end
