# frozen_string_literal: true

class AddCustomListIdsToCoupons < ActiveRecord::Migration[5.2]
  def change
    add_column :coupon_templates, :custom_list_ids, :integer, array: true, default: []
    add_column :coupons, :custom_list_ids, :integer, array: true, default: []
  end
end
