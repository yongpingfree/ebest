# frozen_string_literal: true

class AddMaxRandomReductionCountToCouponTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :coupon_templates, :max_random_reduction_count, :integer, default: 0, null: false
  end
end
