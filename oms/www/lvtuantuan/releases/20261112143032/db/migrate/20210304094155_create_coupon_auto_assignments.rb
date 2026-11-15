# frozen_string_literal: true

class CreateCouponAutoAssignments < ActiveRecord::Migration[5.2]
  def change
    create_table :coupon_auto_assignments do |t|

      t.date :start_date
      t.date :end_date
      t.datetime :last_assigned_at
      t.integer :assign_type, default: 0
      t.integer :assign_user_ids, array: true, default: []
      t.integer :coupon_template_ids, array: true, default: []

      t.timestamps
    end
  end
end
