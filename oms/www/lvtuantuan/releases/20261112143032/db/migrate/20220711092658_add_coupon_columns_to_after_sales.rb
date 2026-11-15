# frozen_string_literal: true

class AddCouponColumnsToAfterSales < ActiveRecord::Migration[5.2]
  def change
    add_column :after_sales, :return_coupon_amount_in_cent, :integer, default: 0
    add_column :after_sales, :return_type, :integer, default: 1
  end
end
