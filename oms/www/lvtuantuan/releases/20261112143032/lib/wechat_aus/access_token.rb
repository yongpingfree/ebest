# frozen_string_literal: true

module WechatAus
  class AccessToken
    ACCESS_TOKEN_CACHE_KEY = "aus_mini_program_access_token"
    WECHAT_CONFIG = Rails.application.credentials.dig(Rails.env.to_sym, :wechat_aus)
    APP_ID = WECHAT_CONFIG[:app_id]
    APP_SECRET = WECHAT_CONFIG[:app_secret]
    ENV_FALLBACK_ARRAY = [:production, :staging, :development]

    # 首先读取内存数据
    # 如内存没有数据
    #   如果当前环境是production, 则直接调用refresh_mini_program_access_token方法获取并保存access_token
    #
    #   如果当前环境是staging, 则请求production环境获取access_token的API
    #     如果production环境API 404, 则直接调用refresh_mini_program_access_token方法获取并保存access_token
    #
    #   如果当前环境是development, 则请求production环境获取access_token的API
    #     如果production环境API 404, 则请求staging环境获取access_token的API
    #       如果staging环境API 404, 则直接调用refresh_mini_program_access_token方法获取并保存access_token
    def self.get_mini_program_access_token
      access_token = Rails.cache.fetch(ACCESS_TOKEN_CACHE_KEY)

      return access_token if access_token

      ENV_FALLBACK_ARRAY.each do |env|
        if Rails.env == env.to_s
          access_token = refresh_mini_program_access_token

          break
        else
          begin
            host = Rails.application.credentials.dig(env, :domain)

            # 未部署的环境暂时不配置host
            next if host.blank?

            resp = RestClient.get("#{host}/app/api/v2/wechat/access_token", "api-authorization-token" => Rails.application.credentials.dig(env, :aus_api_authorization_token))

            next unless access_token = JSON.parse(resp)["access_token"]

            Rails.cache.write(ACCESS_TOKEN_CACHE_KEY, access_token, expires_in: 5.minutes)

            break
          rescue RestClient::NotFound
            next
          end
        end
      end

      access_token
    end

    def self.refresh_mini_program_access_token
      access_token_request = HTTParty.get(
        "https://api.weixin.qq.com/cgi-bin/token",
        query: {
          'grant_type': "client_credential",
          'appid': APP_ID,
          'secret': APP_SECRET
        },
        format: :json)
      access_token_info = JSON.parse(access_token_request.body)
      access_token = access_token_info["access_token"]
      Rails.cache.write(ACCESS_TOKEN_CACHE_KEY, access_token, expires_in: 100.minutes)
      access_token
    end
  end
end
