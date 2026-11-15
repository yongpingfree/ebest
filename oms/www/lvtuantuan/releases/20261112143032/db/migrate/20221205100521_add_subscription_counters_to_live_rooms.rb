# frozen_string_literal: true

class AddSubscriptionCountersToLiveRooms < ActiveRecord::Migration[5.2]
  def change
    add_column :live_rooms, :subscription_count_offset, :integer, default: 0, comment: "订阅基础数"
    add_column :live_rooms, :subscription_count_multiplier, :integer, default: 0, comment: "订阅数乘数"
  end
end
