# frozen_string_literal: true

class AddLiveRoomToLiveRoomLotteryWinningUsers < ActiveRecord::Migration[5.2]
  def change
    add_reference :live_room_lottery_winning_users, :live_room, foreign_key: true
  end
end
