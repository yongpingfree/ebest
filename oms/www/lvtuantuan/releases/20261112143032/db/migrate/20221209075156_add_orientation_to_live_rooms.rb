# frozen_string_literal: true

class AddOrientationToLiveRooms < ActiveRecord::Migration[5.2]
  def change
    add_column :live_rooms, :orientation, :integer, null: false, default: 0
  end
end
