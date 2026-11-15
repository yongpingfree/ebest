# frozen_string_literal: true

class RemoveLiveRoomCouponTemplates < ActiveRecord::Migration[5.2]
  def change
    drop_table :live_room_coupon_templates
  end
end
