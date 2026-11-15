# frozen_string_literal: true

class AddActualCreditCardServiceAmountInCentToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :actual_credit_card_service_amount_in_cent, :integer, default: 0
  end
end
