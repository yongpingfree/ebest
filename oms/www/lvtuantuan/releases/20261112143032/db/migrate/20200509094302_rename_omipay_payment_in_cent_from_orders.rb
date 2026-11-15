# frozen_string_literal: true
class RenameOmipayPaymentInCentFromOrders < ActiveRecord::Migration[5.2]
  def change
    rename_column :orders, :omipay_payment_in_cent, :omipay_payment_dollar_in_cent
  end
end
