# frozen_string_literal: true

module UnionPay
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

    HTTPARTY_TIMEOUT = 5
    RETRY_TIMES = 3
    TRANS_TYPE = { "purchase": "01", "refund": "04", "purchase_cancellation": "31" }
    UNION_PAY = Rails.application.credentials.dig(Rails.env.to_sym, :union_pay)
    SECRET_KEY = UNION_PAY.dig(:secret_key)
    MER_ID = UNION_PAY.dig(:mer_id)
    MER_ABBR = UNION_PAY.dig(:mer_abbr)
    MER_CODE = UNION_PAY.dig(:mer_code)
    URL = UNION_PAY.dig(:url)
    BACKENDURL = Rails.application.credentials.dig(Rails.env.to_sym, :domain)

    base_uri URL

    class << self

      @@logger = ::Logger.new("./log/union_pay.log")

      def logger
        @@logger
      end

      def transaction(options)
        body = {
          bizType: "000000",
          channelType: "07",
          version: "5.0.0",
          charset: "UTF-8",
          signMethod: "MD5",
          merAbbr: MER_ABBR,
          merId: MER_ID,
          merCode: MER_CODE,
          backEndUrl: BACKENDURL,
          frontEndUrl: "",
          frontFailUrl: "",
          transTimeout: 30000,
          commodityName: "",
          merReserved: "",
          origQid: ""
        }.merge(options)

        body[:signature] = signature(body.except(:signMethod))

        response = httparty_post(
          "/AutoPayment5.action",
          body: sort_and_to_query(body),
          log_body: body.except(:cardCvn2, :cardExpiredDate, :acctNum)
        )

        # response
        # "charset=UTF-8&cupReserved=&exchangeDate=&exchangeRate=&merId=620003620200007&orderAmount=399..."
        Rack::Utils.parse_query(response) if response&.body.present?
      end

      def query(options)
        body = {
          version: "5.0.0",
          charset: "UTF-8",
          signMethod: "MD5",
          merId: MER_ID,
        }.merge(options)

        body[:signature] = signature(body.except(:signMethod))

        response = httparty_post(
          "/Query5.action",
          body: sort_and_to_query(body),
          log_body: body.except(:cardCvn2, :cardExpiredDate, :acctNum)
        )

        # response
        # "charset=UTF-8&cupReserved=&exchangeDate=&exchangeRate=&merId=620003620200007&orderAmount=399..."
        Rack::Utils.parse_query(response) if response&.body.present?
      end

      def sort_and_to_query(options)
        options.sort.map { |k, v| "#{k}=#{v}" }.join("&")
      end

      # md5(key1=value1&key2=&key3=value3...&keyn=valuen&md5(secret_key))
      def signature(options)
        md5_secret_key = Digest::MD5.hexdigest(SECRET_KEY)

        signature_str = "#{sort_and_to_query(options)}&#{md5_secret_key}"

        Digest::MD5.hexdigest(signature_str)
      end

      def httparty_post(path, options = {})
        tries = RETRY_TIMES
        body = (options[:body] || {})
        headers = (options[:headers] || {}).reverse_merge(
          "Content-Type" => "text/plain"
        )

        @@logger.debug("request: method: post, url: #{path}, order: #{options[:log_body]}, headers: #{headers}")
        response = begin
                    post(path, body: body, headers: headers, timeout: HTTPARTY_TIMEOUT)
                  rescue *HTTP_ERRORS => error
                    (tries -= 1) > 0 ? retry : { "msg" => "连接超时" }
                  end
        @@logger.debug("response: #{response}")

        response
      end

      def sign_verify?(params)
        signature = signature(params.except("signMethod", "signature"))

        signature.eql?(params["signature"])
      end
    end
  end
end
