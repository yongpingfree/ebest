# frozen_string_literal: true

class AddIsAusQrcodeToMultipleTables < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :is_aus_qrcode, :boolean, default: false
    add_column :custom_pages, :is_aus_qrcode, :boolean, default: false
    add_column :coupon_templates, :is_aus_qrcode, :boolean, default: false
    add_column :coupons, :is_aus_qrcode, :boolean, default: false
  end
end
