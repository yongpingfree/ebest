# frozen_string_literal: true

class AddTrackingNoToThirdPartyOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :third_party_orders, :tracking_no, :string
  end
end
