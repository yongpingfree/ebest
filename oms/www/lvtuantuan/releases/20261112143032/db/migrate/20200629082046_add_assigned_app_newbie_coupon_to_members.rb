# frozen_string_literal: true

class AddAssignedAppNewbieCouponToMembers < ActiveRecord::Migration[5.2]
  def change
    add_column :members, :assigned_app_newbie_coupon, :boolean, default: false
  end
end
