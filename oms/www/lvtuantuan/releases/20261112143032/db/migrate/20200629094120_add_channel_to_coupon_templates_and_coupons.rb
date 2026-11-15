# frozen_string_literal: true

class AddChannelToCouponTemplatesAndCoupons < ActiveRecord::Migration[5.2]
  def change
    add_column :coupon_templates, :channel, :integer, default: 1
    add_column :coupons, :channel, :integer, default: 1
  end
end
