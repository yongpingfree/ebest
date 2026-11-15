# frozen_string_literal: true

class AliexpressController < ApplicationController
  # access_token效期为一年，一年后手动授权
  # 授权地址: https://api-sg.aliexpress.com/oauth/authorize?response_type=code&force_auth=true&redirect_uri=https://minimall.donkibuy.com/aliexpress/token&client_id=506018
  # redirect_uri必须和开发平台的回调地址一致（https://open.aliexpress.com/app/index.htm#/app/overview?id=14138&appkey=506018&_k=8n4xay）
  def token
    response = Aliexpress::Api.generate_access_token(params[:code]).body
    if response["error_response"].blank?
      Rails.cache.redis.set(Aliexpress::Api::ACCESS_TOKEN_KEY, response["access_token"], ex: 1.year)
      Rails.cache.redis.set(Aliexpress::Api::REFRESH_TOKEN_KEY, response["refresh_token"], ex: 1.year)
    end
  end

  # refresh_token最长效期是2个月，access_token每次效期是1个月，2个月后需要手动授权
  # https://api-sg.aliexpress.com/oauth/authorize?response_type=code&force_auth=true&redirect_uri=https://minimall.donkibuy.com/aliexpress/oversea_token&client_id=509542
  def oversea_token
    response = Aliexpress::Api.generate_oversea_access_token(params[:code]).body
    if response["error_response"].blank?
      Rails.cache.redis.set(Aliexpress::Api::OVERSEA_ACCESS_TOKEN_KEY, response["access_token"], ex: 1.month)
      Rails.cache.redis.set(Aliexpress::Api::OVERSEA_REFRESH_TOKEN_KEY, response["refresh_token"], ex: 1.month)
    end
  end
end
