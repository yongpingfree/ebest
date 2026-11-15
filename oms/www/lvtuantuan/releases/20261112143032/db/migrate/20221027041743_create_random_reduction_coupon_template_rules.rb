# frozen_string_literal: true

class CreateRandomReductionCouponTemplateRules < ActiveRecord::Migration[5.2]
  def change
    create_table :random_reduction_coupon_template_rules do |t|
      t.integer :min_amount_in_cent, default: 0, null: false
      t.integer :max_amount_in_cent, default: 0, null: false
      t.integer :max_quantity, default: 0, null: false
      t.integer :used_quantity, default: 0, null: false
      t.references :coupon_template,foreign_key: true, index: { name: :index_random_reduction_rules_on_coupon_template_id }

      t.timestamps
    end
  end
end
