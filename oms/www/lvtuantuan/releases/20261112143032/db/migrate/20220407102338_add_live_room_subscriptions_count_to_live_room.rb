# frozen_string_literal: true

class AddLiveRoomSubscriptionsCountToLiveRoom < ActiveRecord::Migration[5.2]
  def change
    add_column :live_rooms, :live_room_subscriptions_count, :integer, default: 0
  end
end
