# frozen_string_literal: true

class AddMaximunAmountToAfterSalesOrderItems < ActiveRecord::Migration[5.2]
  # 添加max_service_amount_in_cent, max_cost_integral, max_gift_card_amount_in_cent, max_cash_amount_in_cent到after_sales_order_items表
  def change
    add_column :after_sales_order_items, :max_service_amount_in_cent, :integer, default: 0
    add_column :after_sales_order_items, :max_cost_integral, :integer, default: 0
    add_column :after_sales_order_items, :max_gift_card_amount_in_cent, :integer, default: 0
    add_column :after_sales_order_items, :max_cash_amount_in_cent, :integer, default: 0
  end
end
