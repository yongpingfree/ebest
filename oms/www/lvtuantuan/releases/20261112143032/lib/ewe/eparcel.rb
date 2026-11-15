# frozen_string_literal: true

# Jerry-eParcel API
module Ewe
  class Eparcel
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

    HTTPARTY_TIMEOUT = 5
    RETRY_TIMES = 3

    JERRY = Rails.application.credentials.dig(Rails.env.to_sym, :jerry_api)
    USERNAME = JERRY[:eparcel_username]
    PASSWORD = JERRY[:eparcel_password]

    base_uri JERRY[:url]

    @@logger = ::Logger.new("./log/ewe_eparcel.log")

    class << self

      # 物流追踪
      # ['logistics_no1', 'logistics_no2']
      def tracking(logistics_nos)
        return if logistics_nos.empty?

        # 物流追踪接口一次只能提交10个物流单号
        logistics_nos.compact.each_slice(10).to_a.each do |logistics_group|

          request_data = {
            username: USERNAME,
            articleId: logistics_group
          }.to_json

          response = httparty_post(
            "/aupost/trackArticle",
            body: request_data
          )

          if tracking_results = response["tracking_results"]
            tracking_results.each do |tracking_result|
              next if tracking_result["errors"]

              logistic = MagicBean::Logistic.find_by(no: tracking_result["tracking_id"])
              logistic.update(
                traces: tracking_result.dig("trackable_items", 0, "events"),
                is_delivered: tracking_result["status"].eql?(MagicBean::Logistic::DELIVERED)
              )
            end
          end
        end
      end

      def skus_stock(item)
        return [] if item.blank?

        request_data = {
          "USERNAME": USERNAME,
          "APIPASSWORD": PASSWORD,
          "UPCItems": item.stock_keeping_units.map { |sku| { "RetailSKU": sku.id } }
        }.to_json


        httparty_post(
          "/api/getWMSStock",
          body: request_data
        )
      end

      def httparty_post(path, options = {})
        tries = RETRY_TIMES
        body = (options[:body] || {})
        headers = (options[:headers] || {}).reverse_merge(
          "Content-Type" => "application/javascript"
        )

        @@logger.debug("request: method: post, url: #{path}, body: #{body}, headers: #{headers}")
        response = begin
                    post(path, body: body, headers: headers, timeout: HTTPARTY_TIMEOUT)
                  rescue *HTTP_ERRORS => error
                    (tries -= 1) > 0 ? retry : { "msg" => "连接超时" }
                  rescue StandardError => error
                    # 偶尔出现 undefined method body for nil
                    (tries -= 1) > 0 ? retry : { "msg" => "其他错误" }
                  end
        @@logger.debug("response: #{response}")
        response
      end
    end
  end
end
