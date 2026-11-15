# frozen_string_literal: true

class AddDeliveryTypesAndPaymentTypesToCoupons < ActiveRecord::Migration[5.2]
  def change
    add_column :coupon_templates, :delivery_types, :string, array: true, default: []
    add_column :coupon_templates, :payment_types, :string, array: true, default: []

    add_column :coupons, :delivery_types, :string, array: true, default: []
    add_column :coupons, :payment_types, :string, array: true, default: []
  end
end
