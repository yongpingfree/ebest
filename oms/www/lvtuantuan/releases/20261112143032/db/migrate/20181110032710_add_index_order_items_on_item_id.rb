# frozen_string_literal: true

class AddIndexOrderItemsOnItemId < ActiveRecord::Migration[5.2]
  def change
    add_index :order_items, :item_id
  end
end
