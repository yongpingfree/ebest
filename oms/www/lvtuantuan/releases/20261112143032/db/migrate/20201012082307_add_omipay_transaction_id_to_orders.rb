# frozen_string_literal: true

class AddOmipayTransactionIdToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :omipay_transaction_id, :string
  end
end
