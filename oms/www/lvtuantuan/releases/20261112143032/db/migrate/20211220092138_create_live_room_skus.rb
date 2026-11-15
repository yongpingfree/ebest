# frozen_string_literal: true

class CreateLiveRoomSkus < ActiveRecord::Migration[5.2]
  def change
    create_table :live_room_skus do |t|

      t.belongs_to :live_room
      t.belongs_to :stock_keeping_unit
      t.timestamps
    end
  end
end
