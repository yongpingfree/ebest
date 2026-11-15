# frozen_string_literal: true

class AddDrawMethodToLiveRoomLotteries < ActiveRecord::Migration[5.2]
  def change
    add_column :live_room_lotteries, :draw_method, :integer, default: 0, null: false
  end
end
