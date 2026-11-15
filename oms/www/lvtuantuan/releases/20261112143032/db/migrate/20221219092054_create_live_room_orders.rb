class CreateLiveRoomOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :live_room_orders do |t|
      t.references :live_room, foreign_key: true
      t.references :order, foreign_key: true
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
