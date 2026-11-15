# frozen_string_literal: true

class AddInventoryReturnedToThirdPartyOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :third_party_orders, :inventory_returned, :boolean, default: false, comment: "是否已回退库存"
  end
end
