# frozen_string_literal: true

class AddDisplayInItemDetailToCouponTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :coupon_templates, :display_in_item_detail, :boolean, default: false
  end
end
