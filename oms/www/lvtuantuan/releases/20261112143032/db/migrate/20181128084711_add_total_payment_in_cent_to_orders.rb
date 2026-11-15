# frozen_string_literal: true

class AddTotalPaymentInCentToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :total_payment_in_cent, :integer, null: false, default: 0
  end
end
