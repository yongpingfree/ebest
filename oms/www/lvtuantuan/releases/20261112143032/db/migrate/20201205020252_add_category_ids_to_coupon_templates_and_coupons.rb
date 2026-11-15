# frozen_string_literal: true
class AddCategoryIdsToCouponTemplatesAndCoupons < ActiveRecord::Migration[5.2]
  def change
    add_column :coupon_templates, :category_ids, :integer, array: true, default: []
    add_column :coupons, :category_ids, :integer, array: true, default: []
  end
end
