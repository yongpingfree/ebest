# frozen_string_literal: true

module BeansApp::API::Entities
  class PaymentSetting < ::CommonEntities::Model
    expose :store_id
    expose :wechat_service_percentage
    expose :vm_credit_card_service_percentage
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
  end
end
