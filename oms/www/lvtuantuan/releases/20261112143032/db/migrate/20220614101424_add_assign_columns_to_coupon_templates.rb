# frozen_string_literal: true

class AddAssignColumnsToCouponTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :coupon_templates, :assign_start_at, :datetime, comment: "领取开始时间"
    add_column :coupon_templates, :assign_end_at, :datetime, comment: "领取结束时间"
    add_column :coupon_templates, :assign_total_quantity, :integer, default: 0, comment: "可领取总数量"
  end
end
