# frozen_string_literal: true

class CreateCouponPackagesUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :coupon_packages_users, id: false do |t|
      t.integer :coupon_package_id
      t.integer :user_id
    end

    add_index :coupon_packages_users, :coupon_package_id
    add_index :coupon_packages_users, :user_id
    add_index :coupon_packages_users, [:user_id, :coupon_package_id], unique: true
  end
end
