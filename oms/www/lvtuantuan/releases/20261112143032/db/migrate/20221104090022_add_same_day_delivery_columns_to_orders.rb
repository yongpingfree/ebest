# frozen_string_literal: true

class AddSameDayDeliveryColumnsToOrders < ActiveRecord::Migration[5.2]
  def change
    add_belongs_to :orders, :same_day_delivery_time
    add_belongs_to :orders, :same_day_delivery_time_period
  end
end
