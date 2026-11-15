# frozen_string_literal: true

class AddRandomReductionToCouponTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :coupon_templates, :min_denominations_in_cent, :integer
    add_column :coupon_templates, :max_denominations_in_cent, :integer
  end
end
