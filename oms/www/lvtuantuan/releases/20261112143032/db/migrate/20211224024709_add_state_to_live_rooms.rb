# frozen_string_literal: true

class AddStateToLiveRooms < ActiveRecord::Migration[5.2]
  def change
    add_column :live_rooms, :state, :integer, default: 0
    add_column :live_rooms, :finished_at, :datetime
    add_column :live_rooms, :live_at, :datetime
  end
end
