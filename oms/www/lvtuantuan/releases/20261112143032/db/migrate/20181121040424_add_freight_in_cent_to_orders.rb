# frozen_string_literal: true

class AddFreightInCentToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :freight_in_cent, :integer, null: false, default: 0
  end
end
