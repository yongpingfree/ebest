# frozen_string_literal: true

class AddPartyToCoupons < ActiveRecord::Migration[5.2]
  def change
    add_column :coupon_templates, :party, :integer, default: 1, comment: "发券方"
    add_column :coupons, :party, :integer, default: 1, comment: "发券方"
  end
end
