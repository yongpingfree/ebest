# frozen_string_literal: true
class AddStripeTransactionIdToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :stripe_transaction_id, :string
  end
end
