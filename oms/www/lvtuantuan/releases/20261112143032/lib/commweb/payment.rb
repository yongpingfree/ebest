# frozen_string_literal: true

# doc: https://paymentgateway.commbank.com.au/api/documentation/apiDocumentation/rest-json/version/60/api.html?locale=en_US
module Commweb
  class Payment
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

    HTTPARTY_TIMEOUT = 15
    RETRY_TIMES = 3

    MERCHANT = Rails.application.credentials.dig(Rails.env.to_sym, :commweb)
    MERCHANT_ID = MERCHANT[:merchant_id]
    API_PASSWORD = MERCHANT[:api_password]
    APP_MERCHANT_ID = MERCHANT[:app_merchant_id]
    APP_API_PASSWORD = MERCHANT[:app_api_password]
    API_VERSION = 60

    class << self

      @@logger = ::Logger.new("./log/commweb.log")

      # apiOperation: "PAY"
      # apiOperation: "REFUND"
      def transaction(options, ebest_channel = "mini_program")
        body = {
          apiOperation: "PAY"
        }.merge(options)

        resp = call_httparty(
          "put",
          "/order/#{body[:order].delete(:id)}/transaction/#{body[:order].delete(:transaction_id)}",
          ebest_channel,
          body: body.to_json,
          log_body: body[:order]
        )

        # 返回以下数据可以在本地调用 `/app/api/v1/orders/:id/pay_with_commweb_session`
        # 接口来模拟信用卡支付成功
        # ActiveSupport::HashWithIndifferentAccess.new({
        #   result: "SUCCESS",
        #   transaction: {
        #     id: options[:order][:transaction_id],
        #   },
        #   order: {
        #     creationTime: Time.current,
        #     amount: options[:order][:amount]
        #   },
        #   sourceOfFunds: {
        #     provided: {
        #       card: {
        #         brand: "VISA",
        #         number: "4242xxxxxxxx4242"
        #       }
        #     }
        #   }
        # })
      end

      def session(ebest_channel = "mini_program")
        resp = call_httparty(
          "post",
          "/session",
          ebest_channel
        )
      end

      def checkout_session(options, ebest_channel = "app")
        resp = call_httparty(
          "post",
          "/session",
          ebest_channel,
          body: options.to_json
        )
      end

      def retrieve_transaction(order_no, transaction_id, ebest_channel = "mini_program")
        call_httparty(
          "get",
          "/order/#{order_no}/transaction/#{transaction_id}",
          ebest_channel
        )
      end

      def retrieve_order(order_no, ebest_channel = "app")
        call_httparty(
          "get",
          "/order/#{order_no}",
          ebest_channel
        )
      end

      def call_httparty(method, path, ebest_channel, options = {})
        if ebest_channel == "app"
          base_uri "https://paymentgateway.commbank.com.au/api/rest/version/#{API_VERSION}/merchant/#{APP_MERCHANT_ID}"
          basic_auth "merchant.#{APP_MERCHANT_ID}", APP_API_PASSWORD
        else
          # TODO: 确认英文网站的支付网关
          base_uri "https://paymentgateway.commbank.com.au/api/rest/version/#{API_VERSION}/merchant/#{MERCHANT_ID}"
          basic_auth "merchant.#{MERCHANT_ID}", API_PASSWORD
        end
        tries = RETRY_TIMES
        body = (options[:body] || {})
        headers = (options[:headers] || {}).reverse_merge(
          "Content-Type" => "application/json;charset=UTF-8"
        )

        @@logger.debug("request: method: #{method}, url: #{path}, order: #{options[:log_body]}, headers: #{headers}")
        response = begin
                     send method, path, body: body, headers: headers, timeout: HTTPARTY_TIMEOUT
                   rescue *HTTP_ERRORS => error
                     if (tries -= 1) > 0
                       retry
                     else
                       @@logger.debug("response error: #{error}")
                       { "msg" => "连接超时" }
                     end
                   rescue StandardError => error
                     # 偶尔出现 undefined method body for nil
                     if (tries -= 1) > 0
                       retry
                     else
                       @@logger.debug("response error: #{error}")
                       { "msg" => "其他错误" }
                     end
                   end
        response
      end
    end
  end
end
