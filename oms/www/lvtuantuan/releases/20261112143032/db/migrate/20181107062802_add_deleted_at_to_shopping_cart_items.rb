# frozen_string_literal: true

class AddDeletedAtToShoppingCartItems < ActiveRecord::Migration[5.2]
  def change
    add_column :shopping_cart_items, :deleted_at, :datetime
  end
end
