# frozen_string_literal: true
class AddWechatServiceAmountInCentAndCreditCardServiceAmountInCentToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :wechat_service_amount_in_cent, :integer, default: 0
    add_column :orders, :credit_card_service_amount_in_cent, :integer, default: 0
    add_column :orders, :wechat_payment_in_cent, :integer, default: 0
    add_column :orders, :credit_card_payment_in_cent, :integer, default: 0
    add_column :orders, :aud_to_cny_exchange_rate, :decimal, precision: 12, scale: 2, default: "0.0"
  end
end
