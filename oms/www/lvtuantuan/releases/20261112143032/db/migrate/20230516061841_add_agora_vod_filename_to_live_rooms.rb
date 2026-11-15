# frozen_string_literal: true

class AddAgoraVodFilenameToLiveRooms < ActiveRecord::Migration[5.2]
  def change
    add_column :live_rooms, :agora_vod_filename, :string
  end
end
