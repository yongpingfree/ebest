# frozen_string_literal: true

class AddDeletedAtToCouponAutoAssignments < ActiveRecord::Migration[5.2]
  def change
    add_column :coupon_auto_assignments, :deleted_at, :datetime
  end
end
