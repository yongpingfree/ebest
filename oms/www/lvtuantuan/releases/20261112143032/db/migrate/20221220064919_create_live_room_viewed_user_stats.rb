class CreateLiveRoomViewedUserStats < ActiveRecord::Migration[5.2]
  def change
    create_table :live_room_viewed_user_stats do |t|
      t.integer :count, default: 0, null: false
      t.string :time_str, index: true, comment: "精确到分钟的时间"
      t.references :live_room, foreign_key: true

      t.timestamps
    end
  end
end
