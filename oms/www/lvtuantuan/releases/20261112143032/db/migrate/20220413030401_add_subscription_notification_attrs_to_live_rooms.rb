# frozen_string_literal: true

class AddSubscriptionNotificationAttrsToLiveRooms < ActiveRecord::Migration[5.2]
  def change
    add_column :live_rooms, :subscription_noti_title, :string
    add_column :live_rooms, :subscription_noti_body, :string
  end
end
