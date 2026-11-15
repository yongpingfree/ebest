# frozen_string_literal: true

class AddOriginalFreightInCentToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :original_freight_in_cent, :integer
  end
end
