# frozen_string_literal: true

class AddColumnsToSameDayDeliveryTimePeriods < ActiveRecord::Migration[5.2]
  def change
    add_column :same_day_delivery_time_periods, :free_shipping_amount_in_cent, :integer, comment: "免额外运费门槛"
    add_column :same_day_delivery_time_periods, :extra_shipping_amount_in_cent, :integer, comment: "额外运费"
  end
end
