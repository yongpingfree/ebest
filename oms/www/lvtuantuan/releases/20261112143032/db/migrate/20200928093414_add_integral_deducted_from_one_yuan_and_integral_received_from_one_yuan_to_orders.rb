# frozen_string_literal: true

class AddIntegralDeductedFromOneYuanAndIntegralReceivedFromOneYuanToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :integral_received_from_one_yuan, :integer, default: 0
    add_column :orders, :integral_deducted_from_one_yuan, :integer, default: 0
  end
end
