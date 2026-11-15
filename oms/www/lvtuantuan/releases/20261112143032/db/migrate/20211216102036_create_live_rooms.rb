# frozen_string_literal: true

class CreateLiveRooms < ActiveRecord::Migration[5.2]
  def change
    create_table :live_rooms do |t|
      t.string :title, null: false
      t.bigint :host_id, null: false, index: true
      t.string :host_nickname, null: false
      t.datetime :start_at, null: false
      t.bigint :admin_user_id, null: false, index: true

      t.timestamps
    end
  end
end
