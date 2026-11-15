# frozen_string_literal: true

class AddCostAccountingToCouponTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :coupon_templates, :cost_accounting, :integer, comment: "成本核算, 1: 平台, 2: 板块"
  end
end
