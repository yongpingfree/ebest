# frozen_string_literal: true

class AddOrderTypeToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :order_type, :integer, default: 1
  end
end
