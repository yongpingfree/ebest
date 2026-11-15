# frozen_string_literal: true

FactoryBot.define do
  factory :payment_setting, class: "MagicBean::PaymentSetting" do
    wechat_service_percentage { 1 }
    vm_credit_card_service_percentage { 0 }
    unionpay_credit_card_service_percentage { 1 }
    exchange_rate_rise_percentage { 1 }
    omipay_wechat_service_percentage { 1 }
    omipay_alipay_service_percentage { 1 }
    supay_wechat_service_percentage { 1 }
    supay_alipay_service_percentage { 1 }
    enable_commweb_3ds_auth { false }
    apple_pay_service_percentage { 1 }
    cba_apple_pay_service_percentage { 1 }
    cba_google_pay_service_percentage { 1 }
    store { MagicBean::Store.first || association(:store) }
  end
end
