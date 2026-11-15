# frozen_string_literal: true

class AddCouponEnabledToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :coupon_enabled, :boolean, default: true
  end
end
