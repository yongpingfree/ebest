# frozen_string_literal: true

class RemoveMobileFromLiveRoomLotteryWinningUsers < ActiveRecord::Migration[5.2]
  def change
    remove_column :live_room_lottery_winning_users, :mobile, :string
  end
end
