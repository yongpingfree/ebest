# frozen_string_literal: true

# https://www.omipay.com.cn/Help/API_new.html

module Omipay
  class Api
    include HTTParty
    HTTP_ERRORS = [
      EOFError,
      Errno::ECONNRESET,
      Errno::EINVAL,
      Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError,
      Net::ProtocolError,
      Timeout::Error
    ].freeze

    WECHAT_AUS = Rails.application.credentials.dig(Rails.env.to_sym, :wechat_aus)
    OMIPAY_PARAMS = Rails.application.credentials.dig(Rails.env.to_sym, :omipay)
    NONCE_STR = OMIPAY_PARAMS[:nonce_str]
    M_NUMBER = OMIPAY_PARAMS[:m_number]
    SECRET_KEY = OMIPAY_PARAMS[:secret_key]

    HTTPARTY_TIMEOUT = 10
    RETRY_TIMES = 1

    base_uri "https://www.omipay.com.cn/omipay/api/v2"

    @@logger = ::Logger.new("./log/omipay.log")

    class << self

      def path_params
        valid_time = (Time.current.to_f * 1000).to_i
        {
          m_number: M_NUMBER,
          timestamp: valid_time,
          nonce_str: NONCE_STR,
          sign: sign(valid_time)
        }.to_query
      end

      # 微信小程序支付接口
      def make_aus_mp_order(params)
        httparty_post "/MakeAppletOrder?#{params.to_query}&app_id=#{WECHAT_AUS[:app_id]}"
      end

      def make_app_order(params)
        httparty_post "/MakeAPPOrder?#{ params.to_query }"
      end

      def refund(params)
        httparty_post "/Refund?#{ params.to_query }"
      end

      def refund_query(params)
        httparty_get "/QueryRefund?#{ params.to_query }"
      end

      def get_order_by_out_order_no(order_no)
        httparty_get "/QueryOrder?out_order_no=#{ order_no }"
      end

      def get_order(order_no)
        httparty_get "/QueryOrder?order_no=#{ order_no }"
      end

      # 暂时只需要 aud to cny
      def rate
        @rate = Rails.cache.fetch("rate_aud_to_cny")
      end

      # 不设置过期时间，以保证即使更新失败也有可用的汇率
      def set_rate
        response = get_exchange_rate
        rate = response.dig("rate")
        if response.success? && rate.present?
          # 汇率根据配置百分比上浮
          exchange_rate_rise_percentage = MagicBean::SiteConfig.default_config.exchange_rate_rise_percentage.to_f / 100
          rate = rate * (1 + exchange_rate_rise_percentage) if rate > 0
          Rails.cache.write("rate_aud_to_cny", rate.ceil(2))
        end
      end

      def get_exchange_rate(currency: "AUD", base_currency: "CNY")
        # 该汇率一天更新一次
        httparty_get "/GetExchangeRate?currency=#{ currency }&base_currency=#{ base_currency }"
      end

      def sign(valid_time, nonce_str = NONCE_STR)
        valid_string = "#{ M_NUMBER }&#{ valid_time }&#{ nonce_str }&#{ SECRET_KEY }"
        Digest::MD5.hexdigest(valid_string).upcase
      end

      def verify?(result)
        nonce_str = result["nonce_str"]
        timestamp = result["timestamp"]
        return_sign = result["sign"]
        return_code = result["return_code"]

        if nonce_str.blank? || timestamp.blank? || return_sign.blank? || return_code.blank?
          return false
        end

        return_code.eql?("SUCCESS") && return_sign.eql?(sign(timestamp, nonce_str))
      end

      def httparty_get(path)
        tries = RETRY_TIMES
        path = "#{ path }&#{ path_params }"
        @@logger.debug("request: method: get, url: #{ path }")
        response = get(path)
        @@logger.debug("response: #{ response }")
        response
      rescue RestClient::Exceptions::Timeout
        (tries -= 1) > 0 ? retry : { "return_msg" => "连接超时" }
      end

      def httparty_post(path, options = {})
        tries = RETRY_TIMES
        body = (options[:body] || {})
        headers = (options[:headers] || {})
        path = "#{ path }&#{ path_params }"

        @@logger.debug("request: method: post, url: #{ path }, body: #{ body }, headers: #{ headers }")
        response = begin
                    post(path, body: JSON.pretty_generate(body), headers: headers, timeout: HTTPARTY_TIMEOUT)
                  rescue *HTTP_ERRORS => error
                    (tries -= 1) > 0 ? retry : { "return_msg" => "连接超时：#{error.message}" }
                  rescue StandardError => error
                    # 偶尔出现 undefined method body for nil
                    (tries -= 1) > 0 ? retry : { "return_msg" => "其他错误：#{error.message}" }
                  end
        @@logger.debug("response: #{ response }")
        response
      end

      def logger
        @@logger
      end
    end
  end
end
