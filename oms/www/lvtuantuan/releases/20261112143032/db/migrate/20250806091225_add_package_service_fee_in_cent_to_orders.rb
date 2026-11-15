# frozen_string_literal: true

class AddPackageServiceFeeInCentToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :package_service_fee_in_cent, :integer, default: 0, comment: "包装服务费"
    add_column :orders, :package_service_discount_in_cent, :integer, default: 0, comment: "包装服务费"
    add_column :orders, :original_package_service_fee_in_cent, :integer, default: 0, comment: "原始包装服务费"
  end
end
