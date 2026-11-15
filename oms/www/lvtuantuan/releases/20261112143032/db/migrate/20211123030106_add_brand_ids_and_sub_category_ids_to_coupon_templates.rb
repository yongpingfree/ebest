# frozen_string_literal: true

class AddBrandIdsAndSubCategoryIdsToCouponTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :coupon_templates, :brand_ids, :integer, array: true, default: []
    add_column :coupon_templates, :sub_category_ids, :integer, array: true, default: []
  end
end
