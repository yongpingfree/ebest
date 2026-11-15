# frozen_string_literal: true

wechat = Rails.application.credentials.dig(Rails.env.to_sym, :wechat)
# required
WxPay.appid = wechat[:app_id]
WxPay.key = wechat[:mch_key]
WxPay.mch_id = wechat[:mch_id]

# cert, see https://pay.weixin.qq.com/wiki/doc/api/app/app.php?chapter=4_3
# using PCKS12
if Rails.env.staging? || Rails.env.production?
  WxPay.set_apiclient_by_pkcs12(File.read(Rails.root.join("config/apiclient_cert.p12")), wechat[:mch_id])
end
# if you want to use `generate_authorize_req` and `authenticate`
WxPay.appsecret = wechat[:app_secret]

# optional - configurations for RestClient timeout, etc.
WxPay.extra_rest_client_options = {timeout: 2, open_timeout: 3}

#  add logger to wxpay
module WxPay
 class << self
   class_attribute :logger
   self.logger = ::Logger.new(Rails.root.join("log", "wxpay.log"))
 end
end
