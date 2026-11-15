# frozen_string_literal: true

class AddOrdersLimitEveryDayToDeliveryTimes < ActiveRecord::Migration[5.2]
  def change
    add_column :delivery_times, :specific_orders_limit_every_day, :integer, default: 0, comment: "特定订单上限，不受限于系统设置的订单上限"
  end
end
