# frozen_string_literal: true

class CreateLiveRoomUserBlacklists < ActiveRecord::Migration[5.2]
  def change
    create_table :live_room_user_blacklists do |t|
      t.references :user, foreign_key: true
      t.string :mobile, null: false, index: { unique: true }
      t.boolean :enabled, null: false, default: true
      t.boolean :comment_disabled, null: false, default: true
      t.boolean :lottery_disabled, null: false, default: true
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end
  end
end
