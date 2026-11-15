# frozen_string_literal: true

class SetBooleanDefaultValueForCouponTemplates < ActiveRecord::Migration[5.2]
  def change
    change_column_default :coupon_templates, :need_at_least_amount, false
    change_column_default :coupon_templates, :enabled, true
  end
end
