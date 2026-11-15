# frozen_string_literal: true

class AddDeliverToDoorToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :deliver_to_door, :boolean, default: false
  end
end
