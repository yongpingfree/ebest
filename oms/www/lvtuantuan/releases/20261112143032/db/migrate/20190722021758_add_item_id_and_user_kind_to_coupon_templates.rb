# frozen_string_literal: true

class AddItemIdAndUserKindToCouponTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :coupon_templates, :item_ids, :integer, array: true, default: []
    add_column :coupon_templates, :user_kind, :integer
  end
end
