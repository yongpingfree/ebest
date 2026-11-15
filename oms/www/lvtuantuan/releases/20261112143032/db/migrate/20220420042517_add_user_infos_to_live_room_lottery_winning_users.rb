# frozen_string_literal: true

class AddUserInfosToLiveRoomLotteryWinningUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :live_room_lottery_winning_users, :address_id, :bigint
    add_column :live_room_lottery_winning_users, :mobile, :string
    add_column :live_room_lottery_winning_users, :receiver_properties, :hstore
  end
end
