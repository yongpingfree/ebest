# frozen_string_literal: true

class AddCurrentLotteryIdToLiveRooms < ActiveRecord::Migration[5.2]
  def change
    add_reference :live_rooms, :current_lottery, foreign_key: { to_table: :live_room_lotteries }
  end
end
