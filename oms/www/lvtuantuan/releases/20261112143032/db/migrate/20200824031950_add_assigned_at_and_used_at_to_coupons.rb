# frozen_string_literal: true

class AddAssignedAtAndUsedAtToCoupons < ActiveRecord::Migration[5.2]
  def change
    add_column :coupons, :assigned_at, :datetime
    add_column :coupons, :used_at, :datetime

    say_with_time "init_assigned_at_and_used_at" do
      MagicBean::Coupon.reset_column_information
      MagicBean::Coupon.where.not(user_id: nil).each do |coupon|
        update_hash = { assigned_at: coupon.created_at }
        update_hash[:used_at] = coupon.updated_at if coupon.used?
        coupon.update_columns(update_hash)
      end
    end
  end
end
