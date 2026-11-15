# frozen_string_literal: true

class AddSaleCountToItemsAndAddValidOrdersCountToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :sale_count, :integer, default: 0
    add_column :users, :valid_orders_count, :integer, default: 0
  end
end
