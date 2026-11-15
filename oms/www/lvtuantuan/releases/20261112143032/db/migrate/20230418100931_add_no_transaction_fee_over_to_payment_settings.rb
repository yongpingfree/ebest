# frozen_string_literal: true

class AddNoTransactionFeeOverToPaymentSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :payment_settings, :no_transaction_fee_over_amount_in_cent, :integer, comment: "实付满金额免手续费，为空时必收手续费"
    add_column :payment_settings, :display_cba_credit_card_service, :boolean, default: true
    add_column :payment_settings, :display_unionpay_credit_card_service, :boolean, default: true
    add_column :payment_settings, :display_omipay_wechat_service, :boolean, default: false
    add_column :payment_settings, :display_omipay_alipay_service, :boolean, default: false
    add_column :payment_settings, :display_supay_wechat_service, :boolean, default: false
    add_column :payment_settings, :display_supay_alipay_service, :boolean, default: false
    add_column :payment_settings, :display_apple_pay_service, :boolean, default: true
    add_column :payment_settings, :display_cba_apple_pay_service, :boolean, default: true
    add_column :payment_settings, :display_cba_google_pay_service, :boolean, default: true
  end
end
