# frozen_string_literal: true

class CreateLiveRoomViewedUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :live_room_viewed_users do |t|
      t.references :live_room, foreign_key: true
      t.references :user, foreign_key: true

      t.timestamps
    end
    add_index :live_room_viewed_users, [:live_room_id, :user_id], unique: true
  end
end
