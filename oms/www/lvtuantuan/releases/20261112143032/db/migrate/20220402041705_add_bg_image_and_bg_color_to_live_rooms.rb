# frozen_string_literal: true

class AddBgImageAndBgColorToLiveRooms < ActiveRecord::Migration[5.2]
  def change
    add_column :live_rooms, :bg_img, :string
    add_column :live_rooms, :bg_color, :string
  end
end
