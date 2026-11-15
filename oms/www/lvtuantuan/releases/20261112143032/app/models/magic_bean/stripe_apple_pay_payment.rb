# frozen_string_literal: true
module MagicBean
  class StripeApplePayPayment < StripePayment
    def order_payment_mode
      "stripe_apple_pay"
    end
  end
end
