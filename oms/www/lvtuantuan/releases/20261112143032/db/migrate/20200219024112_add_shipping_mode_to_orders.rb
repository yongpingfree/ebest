# frozen_string_literal: true

class AddShippingModeToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :delivery_type, :integer, default: 1
  end
end
