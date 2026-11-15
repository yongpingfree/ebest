# frozen_string_literal: true

class AddQuantityToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :quantity, :integer, default: 0
    add_column :orders, :delivered_at, :datetime
    add_column :orders, :confirmed_at, :datetime
  end
end
