# frozen_string_literal: true

class AddAmexCreditCardServicePercentageToPaymentSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :payment_settings, :amex_credit_card_service_percentage, :float
  end
end
