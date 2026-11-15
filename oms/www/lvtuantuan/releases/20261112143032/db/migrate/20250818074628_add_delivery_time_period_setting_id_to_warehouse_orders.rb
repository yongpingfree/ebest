# frozen_string_literal: true

class AddDeliveryTimePeriodSettingIdToWarehouseOrders < ActiveRecord::Migration[5.2]
  def up
    add_column :warehouse_orders, :delivery_time_period_setting_id, :integer
  end
end
