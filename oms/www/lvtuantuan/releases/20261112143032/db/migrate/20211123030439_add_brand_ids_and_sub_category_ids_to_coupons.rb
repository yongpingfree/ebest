# frozen_string_literal: true

class AddBrandIdsAndSubCategoryIdsToCoupons < ActiveRecord::Migration[5.2]
  def change
    add_column :coupons, :brand_ids, :integer, array: true, default: []
    add_column :coupons, :sub_category_ids, :integer, array: true, default: []
  end
end
