# frozen_string_literal: true

class AddDeliveryTimePeriodSettingIdToOrders < ActiveRecord::Migration[5.2]
  def change
    add_belongs_to :orders, :delivery_time_period_setting
  end
end
