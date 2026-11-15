# frozen_string_literal: true

class AddLotteryWinLimitsToLiveRooms < ActiveRecord::Migration[5.2]
  def change
    add_column :live_rooms, :lottery_win_limits, :integer, default: 0, comment: "中奖次数上限，0 表示不限制"
  end
end
