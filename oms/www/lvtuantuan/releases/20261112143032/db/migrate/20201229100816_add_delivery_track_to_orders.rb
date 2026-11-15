# frozen_string_literal: true
class AddDeliveryTrackToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :delivery_track, :string
  end
end
