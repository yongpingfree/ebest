# frozen_string_literal: true

class AddAddressHousingTypeToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :address_housing_type, :integer, default: 1, comment: "地址房屋类型: 1-住宅, 2-公寓, 3-公司"
  end
end
