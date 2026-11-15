# frozen_string_literal: true

class RefreshAeAccessTokenJob < ApplicationJob
  queue_as :default

  def perform
    response = Aliexpress::Api.refresh_oversea_access_token(Aliexpress::Api.oversea_refresh_token).body
    raise "Refresh oversea access token failed" unless response["access_token"].present?

    Rails.cache.redis.set(Aliexpress::Api::OVERSEA_ACCESS_TOKEN_KEY, response["access_token"], ex: 1.month)
    Rails.cache.redis.set(Aliexpress::Api::OVERSEA_REFRESH_TOKEN_KEY, response["refresh_token"], ex: 1.month)
  end
end
