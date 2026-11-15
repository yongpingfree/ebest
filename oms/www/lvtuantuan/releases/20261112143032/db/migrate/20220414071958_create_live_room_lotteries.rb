# frozen_string_literal: true

class CreateLiveRoomLotteries < ActiveRecord::Migration[5.2]
  def change
    create_table :live_room_lotteries do |t|
      t.string :name, null: false
      t.integer :luck_limit, null: false, default: 0
      t.integer :duration_in_minutes, null: false
      t.integer :state, null: false, default: 0
      t.datetime :started_at
      t.integer :participators_count, null: false, default: 0
      t.string :award_cover, null: false
      t.string :remark
      t.references :live_room, foreign_key: true

      t.timestamps
    end
  end
end
