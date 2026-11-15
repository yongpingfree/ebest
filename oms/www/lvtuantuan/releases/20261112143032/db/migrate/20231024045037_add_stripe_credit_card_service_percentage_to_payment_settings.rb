# frozen_string_literal: true
class AddStripeCreditCardServicePercentageToPaymentSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :payment_settings, :stripe_credit_card_service_percentage, :float
    add_column :payment_settings, :stripe_apple_pay_service_percentage, :float
    add_column :payment_settings, :stripe_google_pay_service_percentage, :float
    add_column :payment_settings, :display_stripe_credit_card_service, :boolean, default: false
    add_column :payment_settings, :display_stripe_apple_pay_service, :boolean, default: false
    add_column :payment_settings, :display_stripe_google_pay_service, :boolean, default: false
  end
end
