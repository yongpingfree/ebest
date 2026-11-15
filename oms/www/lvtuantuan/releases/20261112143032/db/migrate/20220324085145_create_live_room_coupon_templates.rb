class CreateLiveRoomCouponTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :live_room_coupon_templates do |t|

      t.belongs_to :live_room
      t.belongs_to :coupon_template
      t.timestamps
    end
  end
end
