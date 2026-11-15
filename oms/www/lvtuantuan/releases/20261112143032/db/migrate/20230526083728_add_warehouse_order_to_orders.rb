# frozen_string_literal: true

class AddWarehouseOrderToOrders < ActiveRecord::Migration[5.2]
  def change
    add_reference :orders, :warehouse_order, foreign_key: true
  end
end
