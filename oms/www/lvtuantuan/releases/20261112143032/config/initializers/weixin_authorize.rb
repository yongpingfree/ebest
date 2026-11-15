# frozen_string_literal: true

WeixinAuthorize.configure do |config|
  config.redis = RedisClient
end

wechat_account = Rails.application.credentials.dig(Rails.env.to_sym, :wechat)
$wechat_client ||= WeixinAuthorize::Client.new(
  wechat_account[:official_id],
  wechat_account[:official_secret]
)

$mobile_app_client ||= WeixinAuthorize::Client.new(wechat_account[:mobile_app_id], wechat_account[:mobile_app_secret])
