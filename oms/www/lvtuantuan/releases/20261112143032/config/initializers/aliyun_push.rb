# frozen_string_literal: true

Aliyun::Push.configure do |config|
  aliyun_push_conf = Rails.application.credentials.dig(Rails.env.to_sym, :aliyun_push)
  config.access_key_secret = aliyun_push_conf[:access_key_secret]
  config.access_key_id = aliyun_push_conf[:access_key_id]
  config.android_app_key = aliyun_push_conf[:android_app_key]
  config.ios_app_key = aliyun_push_conf[:ios_app_key]
end
