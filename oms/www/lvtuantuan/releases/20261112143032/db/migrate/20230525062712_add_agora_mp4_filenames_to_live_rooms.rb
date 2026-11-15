# frozen_string_literal: true

class AddAgoraMp4FilenamesToLiveRooms < ActiveRecord::Migration[5.2]
  def change
    add_column :live_rooms, :agora_mp4_filenames, :string, array: true, default: []
  end
end
