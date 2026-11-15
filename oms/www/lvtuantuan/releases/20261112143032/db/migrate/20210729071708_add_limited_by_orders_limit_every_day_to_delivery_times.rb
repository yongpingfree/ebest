# frozen_string_literal: true

class AddLimitedByOrdersLimitEveryDayToDeliveryTimes < ActiveRecord::Migration[5.2]
  def change
    add_column :delivery_times, :limited_by_orders_limit_every_day, :boolean, default: true
    add_column :orders, :mark_for_orders_limit, :boolean, default: true, comment: "是否计算入每日上限订单数"
  end
end
