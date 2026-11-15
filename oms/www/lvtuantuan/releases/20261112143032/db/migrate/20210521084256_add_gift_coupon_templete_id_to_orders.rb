# frozen_string_literal: true

class AddGiftCouponTempleteIdToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :gift_coupon_template_id, :integer
    add_index :orders, :gift_coupon_template_id
  end
end
