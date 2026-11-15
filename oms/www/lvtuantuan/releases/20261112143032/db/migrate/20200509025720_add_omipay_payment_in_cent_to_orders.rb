# frozen_string_literal: true
class AddOmipayPaymentInCentToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :omipay_payment_in_cent, :integer, default: 0
  end
end
