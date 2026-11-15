# frozen_string_literal: true

class AddAnnouncementToLiveRooms < ActiveRecord::Migration[5.2]
  def change
    add_column :live_rooms, :announcement, :string
  end
end
