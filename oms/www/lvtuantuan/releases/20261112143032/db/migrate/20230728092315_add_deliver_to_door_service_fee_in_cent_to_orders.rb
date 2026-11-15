# frozen_string_literal: true

class AddDeliverToDoorServiceFeeInCentToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :deliver_to_door_service_fee_in_cent, :integer, default: 0, comment: "送货上门服务费"
  end
end
