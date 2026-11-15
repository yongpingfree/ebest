# frozen_string_literal: true
module MagicBean
  class StripeGooglePayPayment < StripePayment
    def order_payment_mode
      "stripe_google_pay"
    end
  end
end
