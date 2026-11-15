# frozen_string_literal: true

class AddCostIntegralToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :cost_integral, :integer, default: 0
  end
end
