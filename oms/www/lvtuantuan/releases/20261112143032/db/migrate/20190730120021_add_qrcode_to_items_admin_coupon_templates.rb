# frozen_string_literal: true

class AddQrcodeToItemsAdminCouponTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :qrcode, :string
    add_column :coupon_templates, :qrcode, :string
  end
end
