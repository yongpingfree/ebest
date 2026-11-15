# frozen_string_literal: true

module Nxcloud
  class SMS
    include HTTParty

    URL = "https://api.nxcloud.com/v1/sms/mt"
    BIZ_TYPE = "3"
    ACTION = "mtsend"
    TIMEOUT = 20
    SUCCESS_CODES = %w[0 0000 200 OK ok SUCCESS success].freeze

    class << self
      def send_message(phone, message)
        body_json = request_body(phone, message).to_json
        response = post(url, body: body_json, headers: request_headers(body_json), timeout: TIMEOUT)
        handle_response(response)
      end

      private

      def request_body(phone, message)
        {
          appKey: config_value(:app_key, :appKey),
          phone: phone,
          content: message
        }.tap do |body|
          source_address = config_value(:source_address, :sourceAddress, required: false)
          body[:sourceAddress] = source_address if source_address.present?
        end
      end

      def request_headers(body_json)
        timestamp = (Time.current.to_f * 1000).to_i.to_s
        unsigned_headers = {
          "accessKey" => config_value(:access_key, :accessKey),
          "action" => ACTION,
          "bizType" => BIZ_TYPE,
          "ts" => timestamp
        }

        unsigned_headers.merge(
          "sign" => sign(unsigned_headers, body_json),
          "Content-Type" => "application/json"
        )
      end

      def sign(unsigned_headers, body_json)
        headers_str = unsigned_headers.sort_by { |key, _value| key }.map { |key, value| "#{key}=#{value}" }.join("&")
        sign_str = "#{headers_str}&body=#{body_json}&accessSecret=#{config_value(:access_secret, :accessSecret)}"

        Digest::MD5.hexdigest(sign_str)
      end

      def handle_response(response)
        parsed_response = parse_response(response)
        return parsed_response if success?(response, parsed_response)

        logger.error("Nxcloud SMS send failed: http_status=#{response.code}, response=#{response.body}")
        parsed_response
      end

      def success?(response, parsed_response)
        response.code.to_i.between?(200, 299) &&
          (
            SUCCESS_CODES.include?(parsed_response["code"].to_s) ||
            parsed_response.dig("data", "messageid").present?
          )
      end

      def parse_response(response)
        parsed_response = response.parsed_response.presence || JSON.parse(response.body)
        parsed_response.is_a?(Hash) ? parsed_response : {}
      rescue JSON::ParserError
        {}
      end

      def url
        URL
      end

      def config
        Rails.application.credentials.dig(Rails.env.to_sym, :nxcloud) || {}
      end

      def config_value(*keys, required: true)
        value = keys.lazy.map { |key| config[key] || config[key.to_s] }.find(&:present?)
        return value if value.present?

        raise "Nxcloud SMS config missing: #{keys.join('/')}" if required
      end

      def logger
        @logger ||= Logger.new(Rails.root.join("log", "nxcloud.log"))
      end
    end
  end
end
