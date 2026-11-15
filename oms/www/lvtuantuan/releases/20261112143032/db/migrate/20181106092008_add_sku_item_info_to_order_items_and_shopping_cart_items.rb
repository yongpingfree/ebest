# frozen_string_literal: true

class AddSkuItemInfoToOrderItemsAndShoppingCartItems < ActiveRecord::Migration[5.2]
  def change
    add_column :order_items, :properties_text, :string
    add_column :order_items, :title, :string
    add_column :order_items, :image, :string
  end
end
