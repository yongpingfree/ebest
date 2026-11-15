# frozen_string_literal: true

class AddUsageKindToCouponTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :coupon_templates, :usage_kind, :integer
  end
end
