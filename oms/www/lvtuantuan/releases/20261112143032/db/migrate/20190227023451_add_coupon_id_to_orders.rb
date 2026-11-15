# frozen_string_literal: true

class AddCouponIdToOrders < ActiveRecord::Migration[5.2]
  def change
    add_reference :orders, :coupon, index: true
  end
end
