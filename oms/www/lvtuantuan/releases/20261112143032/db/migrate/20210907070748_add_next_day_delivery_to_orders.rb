# frozen_string_literal: true

class AddNextDayDeliveryToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :next_day_delivery, :boolean, default: false
    add_index :orders, :next_day_delivery
  end
end
