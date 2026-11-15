# frozen_string_literal: true

class AddCouponPackageToLiveRooms < ActiveRecord::Migration[5.2]
  def change
    add_reference :live_rooms, :coupon_package, foreign_key: true
  end
end
