# frozen_string_literal: true

module BeansAdmin::API::Entities
  class PaymentSetting < ::CommonEntities::Model
    expose :store_id
    expose :wechat_service_percentage
    expose :vm_credit_card_service_percentage
    expose :amex_credit_card_service_percentage
    expose :unionpay_credit_card_service_percentage
    expose :exchange_rate_rise_percentage
    expose :omipay_wechat_service_percentage
    expose :omipay_alipay_service_percentage
    expose :supay_wechat_service_percentage
    expose :supay_alipay_service_percentage
    expose :enable_commweb_3ds_auth
    expose :apple_pay_service_percentage
    expose :cba_apple_pay_service_percentage
    expose :cba_google_pay_service_percentage
    expose :stripe_credit_card_service_percentage
    expose :stripe_apple_pay_service_percentage
    expose :stripe_google_pay_service_percentage
    expose :no_transaction_fee_over_amount_in_cent
    expose :no_transaction_fee_over_amount_in_yuan
    expose :display_cba_credit_card_service
    expose :display_unionpay_credit_card_service
    expose :display_omipay_wechat_service
    expose :display_omipay_alipay_service
    expose :display_supay_wechat_service
    expose :display_supay_alipay_service
    expose :display_apple_pay_service
    expose :display_cba_apple_pay_service
    expose :display_cba_google_pay_service
    expose :display_stripe_credit_card_service
    expose :display_stripe_apple_pay_service
    expose :display_stripe_google_pay_service
  end
end
