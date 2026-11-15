# frozen_string_literal: true

class AddMerchantTotalOrdersCountToOrderLimit < ActiveRecord::Migration[5.2]
  def change
    change_column :site_configs, :merchant_delivery_orders_limit_every_day, :integer, default: 0, comment: "每日地址数配送上限"
    add_column :site_configs, :merchant_delivery_total_orders_limit_every_day, :integer, default: 0, comment: "每日总订单配送上限"
    change_column :delivery_times, :specific_orders_limit_every_day, :integer, default: 0, comment: "特定订单上限，不受限于系统设置的地址数配送上限"
    add_column :delivery_times, :specific_total_orders_limit_every_day, :integer, default: 0, comment: "特定订单上限，不受限于系统设置的订单配送上限"
    change_column :extra_orders_limits, :extra_merchant_delivery_orders_limit, :integer, default: 0, comment: "额外地址数配送上限"
    add_column :extra_orders_limits, :extra_merchant_delivery_total_orders_limit, :integer, default: 0, comment: "额外订单配送上限"
  end
end
