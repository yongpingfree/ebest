# frozen_string_literal: true

class AddItemIdToOrderItems < ActiveRecord::Migration[5.2]
  def change
    add_column :order_items, :item_id, :integer
  end
end
