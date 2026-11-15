# frozen_string_literal: true

class AddShoplineCustomerIdToThirdPartyOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :third_party_orders, :customer_id, :string
  end
end
