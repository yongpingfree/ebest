# frozen_string_literal: true

class AddLiveAttrsToLiveRooms < ActiveRecord::Migration[5.2]
  def change
    add_column :live_rooms, :app_push_protocol, :integer, default: 1, null: false
    add_column :live_rooms, :app_pull_protocol, :integer, default: 0, null: false
    add_column :users, :is_host, :boolean, false: false
  end
end
