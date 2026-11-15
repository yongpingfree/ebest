# frozen_string_literal: true
class CreateCouponPackages < ActiveRecord::Migration[5.2]
  def change
    create_table :coupon_packages do |t|
      t.string :name
      t.string :code
      t.integer :status, default: 1
      t.integer :user_kind, default: 1
      t.integer :coupon_template_ids, default: [], array: :true
      t.string :cover
      t.datetime :start_at, default: "-infinity"
      t.datetime :end_at, default: "infinity"

      t.timestamps
    end
  end
end
