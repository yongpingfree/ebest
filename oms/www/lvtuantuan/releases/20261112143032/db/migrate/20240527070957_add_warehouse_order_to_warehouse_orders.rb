# frozen_string_literal: true
class AddWarehouseOrderToWarehouseOrders < ActiveRecord::Migration[5.2]
  def change
    add_belongs_to :third_party_orders, :warehouse_order
  end
end
