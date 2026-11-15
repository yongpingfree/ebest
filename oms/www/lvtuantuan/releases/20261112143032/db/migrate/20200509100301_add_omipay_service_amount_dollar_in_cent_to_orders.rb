# frozen_string_literal: true
class AddOmipayServiceAmountDollarInCentToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :omipay_service_amount_dollar_in_cent, :integer, default: 0
  end
end
