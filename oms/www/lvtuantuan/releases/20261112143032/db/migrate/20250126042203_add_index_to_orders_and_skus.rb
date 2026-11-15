# frozen_string_literal: true

class AddIndexToOrdersAndSkus < ActiveRecord::Migration[5.2]
  def change
    add_index :orders, :created_at
    add_index :orders, :delivery_date
    add_index :stock_keeping_units, :created_at
  end
end
