# frozen_string_literal: true

class AddNewColumnsToOrderItems < ActiveRecord::Migration[5.2]
  # 订单项记录实付现金、均摊手续费、金币、礼品卡金额
  # 售后订单项记录实际退款现金、金币、礼品卡、手续金额
  def change
    add_column :order_items, :service_amount_in_cent, :integer, default: 0, comment: "均摊手续费($)"
    add_column :order_items, :cost_integral, :integer, default: 0, comment: "均摊金币数量"
    add_column :order_items, :gift_card_amount_in_cent, :integer, default: 0, comment: "均摊礼品卡($)"
    add_column :after_sales_order_items, :cash_amount_in_cent, :integer, default: 0, comment: "实际退款现金($)"
    add_column :after_sales_order_items, :service_amount_in_cent, :integer, default: 0, comment: "实际手续费($)"
    add_column :after_sales_order_items, :cost_integral, :integer, default: 0, comment: "实际金币数量"
    add_column :after_sales_order_items, :gift_card_amount_in_cent, :integer, default: 0, comment: "实际礼品卡($)"
  end
end
