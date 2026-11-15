# frozen_string_literal: true

class AddTargetKindToCouponTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :coupon_templates, :target_kind, :integer, default: 1
    add_column :coupons, :target_kind, :integer, default: 1
  end
end
