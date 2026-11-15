# frozen_string_literal: true

class AddDeliveryPathToThirdPartyOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :third_party_orders, :delivery_path, :string, comment: "配送路线"
    add_column :third_party_orders, :delivery_track, :string, comment: "物流追踪"
    add_column :third_party_orders, :eta, :datetime
    add_column :third_party_orders, :ata, :datetime
  end
end
