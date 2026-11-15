# frozen_string_literal: true

class AddPaymentTypeToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :payment_type, :string

    say_with_time "update old order's payment_type" do
      MagicBean::Order.where.not(paid_at: nil).each do |order|
        payment_type = case order.completed_charge_payment&.type
                       when "MagicBean::WechatPayment"
                         "wechat"
                       when "MagicBean::StripePayment"
                         "stripe_credit_card"
                       when "MagicBean::StripeGooglePayPayment"
                         "stripe_google_pay"
                       when "MagicBean::StripeApplePayPayment"
                         "stripe_apple_pay"
                       when "MagicBean::CommwebPayment"
                         "credit_card"
                       when "MagicBean::UnionPayPayment"
                         "union_pay"
                       when "MagicBean::OmipayPayment"
                         "omipay"
                       when "MagicBean::ApplePayPayment"
                         "apple_pay"
                       when "MagicBean::CBAApplePayPayment"
                         "cba_apple_pay"
                       when "MagicBean::CBAGooglePayPayment"
                         "cba_google_pay"
                       end
        order.update(payment_type: payment_type)
      end
    end
  end
end
