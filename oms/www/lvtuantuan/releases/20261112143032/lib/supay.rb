# frozen_string_literal: true

# https://doc.supaytechnology.com/CN/online/index.html

module Supay
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

    SUPAY_PARAMS = Rails.application.credentials.dig(Rails.env.to_sym, :supay)
    MCH_ID = SUPAY_PARAMS[:mch_id]
    BIZ_MCH_ID = SUPAY_PARAMS[:biz_mch_id] # 系统接入商
    # 接口文档就是用这参数，不是拼错
    RECEVICE_ID = SUPAY_PARAMS[:recevice_id]
    API_KEY = SUPAY_PARAMS[:md5_key]

    HTTPARTY_TIMEOUT = 10
    RETRY_TIMES = 1
    GATEWAY_URL = "https://gate.supaytechnology.com/api/gateway/merchant"
    TRADE_URL = "https://tradeserver.supaytechnology.com/v1"

    @@logger = ::Logger.new("./log/supay.log")

    class << self
      def query_params(params)
        params.merge!({
          mch_id: "#{MCH_ID}",
          charset: "UTF-8",
          version: "1.0",
        })

        # URI.decode(params.to_query) 也能排序，但会把空格转成+，为防止更多情况，还是手动拼接
        sign = Digest::MD5.hexdigest(params.sort.map { |k, v| "#{k}=#{v}" }.join("&") + "&key=#{API_KEY}").upcase
        params[:sign] = sign
        params[:sign_type] = "MD5"
        params
      end

      # 汇率接口
      def tradeserver_params(channel)
        params = {
          channelName: channel,
          bizMchId: "#{BIZ_MCH_ID}",
        }
        sign = Digest::MD5.hexdigest(params.sort.map { |k, v| "#{k}=#{v}" }.join("&") + "&key=#{API_KEY}").upcase
        params[:sign] = sign

        params.to_query
      end

      def make_app_order(params)
        params.merge!(
          {
            recevice_id: "#{RECEVICE_ID}",
            call_back_url: "#{Rails.application.credentials.dig(Rails.env.to_sym, :domain)}/orders/supay_notify",
          })
        httparty_post("/order", GATEWAY_URL, body: query_params(params).to_json)
      end

      # {"status"=>"T", "message"=>nil, "data"=>{"result"=>true, "sign"=>"2ef5d941fa189458bc1c19bca97fa703", "sign_type"=>"MD5"}}
      def refund(params)
        httparty_post("/order", GATEWAY_URL, body: query_params(params).to_json)
      end

      def get_order(order_no)
        params = {
          service: "query_trade",
          mch_order_no: order_no,
          trade_type: "INSTANT"
        }

        httparty_post("/order", GATEWAY_URL, body: query_params(params).to_json)
      end

      # channel: alipay/wechat
      def rate(channel)
        Rails.cache.fetch("supay_#{channel}_rate_aud_to_cny")
      end

      def set_rate(channel)
        response = httparty_get "/queryRate?#{tradeserver_params(channel)}", TRADE_URL

        if response["success"] == "true"
          rate = response["rate"].to_f
          # 汇率根据配置百分比上浮
          exchange_rate_rise_percentage = MagicBean::SiteConfig.default_config.exchange_rate_rise_percentage.to_f / 100
          rate = rate * (1 + exchange_rate_rise_percentage) if rate > 0
          Rails.cache.write("supay_#{channel}_rate_aud_to_cny", rate.ceil(2))
        end
      end

      def verify?(result)
        result.except!("controller", "action", "sign_type")
        sign = result.delete("sign")
        sign_str = result.sort.map { |k, v| "#{k}=#{v}" }.join("&") + "&key=#{API_KEY}"
        Digest::MD5.hexdigest(sign_str).upcase == sign
      end

      def httparty_post(path, base_url, options = {})
        base_uri base_url
        tries = RETRY_TIMES
        body = (options[:body] || {})
        headers = (options[:headers] || {}).reverse_merge(
          "Content-Type" => "application/json"
        )


        @@logger.debug("request: method: post, url: #{ path }, body: #{ body }, headers: #{ headers }")
        response = begin
                    post(path, body: body, headers: headers, timeout: HTTPARTY_TIMEOUT)
                  rescue *HTTP_ERRORS => error
                    (tries -= 1) > 0 ? retry : { "return_msg" => "连接超时：#{error.message}" }
                  rescue StandardError => error
                    # 偶尔出现 undefined method body for nil
                    (tries -= 1) > 0 ? retry : { "return_msg" => "其他错误：#{error.message}" }
                  end
        @@logger.debug("response: #{ response }")
        response
      end

      def httparty_get(path, base_url)
        base_uri base_url

        tries = RETRY_TIMES
        @@logger.debug("request: method: get, url: #{ path }")
        response = get(path)
        @@logger.debug("response: #{ response }")
        response
      rescue RestClient::Exceptions::Timeout
        (tries -= 1) > 0 ? retry : { "return_msg" => "连接超时" }
      end

      def logger
        @@logger
      end
    end
  end
end
