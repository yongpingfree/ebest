class CreateLiveRoomLotteryWinningUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :live_room_lottery_winning_users do |t|
      t.references :live_room_lottery, foreign_key: true
      t.references :user, foreign_key: true

      t.timestamps
    end

    add_index :live_room_lottery_winning_users, [:live_room_lottery_id, :user_id], unique: true, name: "index_lottery_winning_users_on_lottery_id_and_user_id"
  end
end
