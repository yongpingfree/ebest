# frozen_string_literal: true

class CreateShoppingCartItems < ActiveRecord::Migration[5.2]
  def change
    create_table :shopping_cart_items do |t|
      t.integer :quantity, default: 1
      t.references :shopping_cart
      t.references :stock_keeping_unit

      t.timestamps
    end
  end
end
