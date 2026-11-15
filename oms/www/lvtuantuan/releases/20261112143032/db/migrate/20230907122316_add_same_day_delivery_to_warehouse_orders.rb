# frozen_string_literal: true

class AddSameDayDeliveryToWarehouseOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :warehouse_orders, :same_day_delivery, :boolean, default: false
  end
end
