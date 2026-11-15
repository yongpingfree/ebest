# frozen_string_literal: true

class AddShareIconToLiveRooms < ActiveRecord::Migration[5.2]
  def change
    add_column :live_rooms, :share_icon, :string
  end
end
