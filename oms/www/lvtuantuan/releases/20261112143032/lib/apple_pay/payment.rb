# frozen_string_literal: true
# require "openssl"
# require "openssl/digest"
require "gala"

module ApplePay
  class Payment
    HTTP_ERRORS = [
      EOFError,
      Errno::ECONNRESET,
      Errno::EINVAL,
      Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError,
      Net::ProtocolError,
      Timeout::Error
    ].freeze

    UNION_PAY_CONFIG = Rails.application.credentials.dig(Rails.env.to_sym, :union_pay)
    WEB_APPLE_PAY_CONFIG = Rails.application.credentials.dig(Rails.env.to_sym, :web_apple_pay)

    VERSION = "5.0.0"
    CHARTSET = "UTF-8"

    # APPLE信息
    MER_ID = UNION_PAY_CONFIG[:mer_id]
    MER_NAME = UNION_PAY_CONFIG[:mer_abbr]
    MER_CODE = UNION_PAY_CONFIG[:mer_code]
    SECURITY_KEY = UNION_PAY_CONFIG[:secret_key]

    # 基础网址（请按相应环境切换）香港测试系统
    UPOP_BSPAY_BASE_URL = UNION_PAY_CONFIG[:apple_pay_url]
    BACK_STAGE_GATEWAY = UPOP_BSPAY_BASE_URL + "/AutoPayment5.action"
    QUERY_ORDER_UTL = UPOP_BSPAY_BASE_URL + "/Query5.action"

    # 后台交易测试环境
    DOMAIN = Rails.application.credentials.dig(Rails.env.to_sym, :domain)
    MER_FRONT_END_URL = DOMAIN # 必传，但没实际意义，所以只传domain
    MER_BACK_END_URL = "#{DOMAIN}/orders/apple_pay_notify"
    MER_FRONT_FAIL_URL = DOMAIN # 必传，但没实际意义，所以只传domain

    TRANS_TYPE = { "purchase": "01", "refund": "04", "purchase_cancellation": "31" }

    RETRY_TIMES = 3

    class << self

      @@logger = ::Logger.new("./log/apple_pay.log")

      def logger
        @@logger
      end

      def transaction(options)
        body = {
          bizType: "000802",
          channelType: "08",  # UPOP 5.0 新加參數, PC端07，移动端08
          charset: ApplePay::Payment::CHARTSET, #字符编码
          commodityName: "Product #{MER_NAME}", #商品名称
          customerIp: "127.0.0.1",  #用户IP
          backEndUrl: MER_BACK_END_URL,  # 后台回调商户URL
          frontEndUrl: MER_FRONT_END_URL,  # 前台回调商户URL
          frontFailUrl: MER_FRONT_FAIL_URL,  # UPOP 5.0 新加參數
          merAbbr: MER_NAME, #商户简称
          merCode: ApplePay::Payment::MER_CODE,
          merId: ApplePay::Payment::MER_ID, #商户代码
          merReserved: nil,  #商户保留域
          orderCurrency: "036", #交易币种
          origQid: nil, #原始交易流水号
          transTimeout: "30000",  #交易超时时间
          version: ApplePay::Payment::VERSION, #协议版本
        }.merge(options)

        query_body = create_back_str_for_back_trans(body)
        response = post_query(BACK_STAGE_GATEWAY, query_body)
        Rack::Utils.parse_query(response) if response&.code.to_i == 200 && response&.body.present?
      end

      def query_order(body)
        # charset=UTF-8&cupReserved=&exchangeDate=1213&exchangeRate=77180907&orderAmount=1&orderCurrency=036&payCardType=02&qid=772112131741299774008&queryResult=0&respCode=00&respMsg=Success%21&respTime=&settleAmount=1&settleCurrency=840&settleDate=20211213&signMethod=md5&signature=c6e108d088e4acb9d9c0b9da22b6a66a&traceNumber=977400&traceTime=1213174129&transType=01&version=5.0.0
        response = post_query(QUERY_ORDER_UTL, body)
        if response&.code.to_i == 200 && response&.body.present?
          Rack::Utils.parse_nested_query(response.body)
        else
          {}
        end
      end

      # https://developer.apple.com/documentation/applepayontheweb/requesting-an-apple-pay-payment-session
      # https://developer.apple.com/cn/help/account/capabilities/configure-apple-pay-on-the-web/
      def merchant_validation(url, platform)
        data = {
          "merchantIdentifier" => WEB_APPLE_PAY_CONFIG[:merchant_identifiers],
          "displayName" => "eBest",
          "initiative" => "web",
          "initiativeContext" => WEB_APPLE_PAY_CONFIG["#{platform}_domains".to_sym]
        }

        # 证书来源：Apple Pay Merchant Identity Certificate
        certificate_pem = File.read(Rails.root.join("config/apple_pay_merchant_cert.pem"))
        private_key_pem = File.read(Rails.root.join("config/apple_pay_merchant_key.pem"))

        tries = RETRY_TIMES
        begin
          res = RestClient::Request.execute(
            method: :post,
            url: url,
            payload: data.to_json,
            ssl_version: :TLSv1_2,
            ssl_ciphers: ["ECDHE-RSA-AES128-GCM-SHA256"],
            ssl_client_cert: OpenSSL::X509::Certificate.new(certificate_pem),
            ssl_client_key: OpenSSL::PKey::RSA.new(private_key_pem, WEB_APPLE_PAY_CONFIG[:cert_passphrase]),
            verify_ssl: OpenSSL::SSL::VERIFY_PEER
          )
          JSON.parse res.body if res.code.to_i == 200
        rescue *HTTP_ERRORS => _
          (tries -= 1) > 0 ? retry : nil
        rescue => _
          nil
        end
      end

      def post_query(url, body)
        tries = RETRY_TIMES

        logger.debug("Apple Pay request: method: post, url: #{url}, body: #{body.to_json}")
        begin
          res = RestClient.post(url, body, { content_type: "application/x-www-form-urlencoded" })
          logger.debug("Apple Pay request successfully, code: #{res.code}, body: #{res.body}")
          res
        rescue *HTTP_ERRORS => error
          logger.debug("Apple Pay request fail, error: #{error}")
          (tries -= 1) > 0 ? retry : { "msg" => "连接超时" }
        end
      end

      def valid_security(array)
        hash = {}
        array.each do |str|
          arr = str.split("=")
          hash[arr[0]] = arr.length >= 2 ? arr[1..-1].join("=") : ""
        end

        return 2 if hash["signature"].to_s == ""
        signature = hash["signature"]

        hash.delete("signature")
        hash.delete("signMethod")
        str_before_md5 = hash.map { |key, value| "#{key}=#{value}" }.join("&") + "&" + Digest::MD5.hexdigest(SECURITY_KEY)
        str_after_md5 = Digest::MD5.hexdigest(str_before_md5)
        signature == str_after_md5
      end

      def create_back_str_for_back_trans(hash)
        hash[:signature] = sign_map(hash)
        hash[:signMethod] = "md5"

        hash.map do |key, value|
          value = URI.encode(value, /\W/) if key.to_s.in?(%w(backEndUrl frontEndUrl frontFailUrl cardTransData customerInfo))
          "#{key}=#{value}"
        end.join("&")
      end

      def sign_map(target_hash)
        target_str = target_hash.sort.map { |key, value| "#{key}=#{value}" }.join("&") + "&" + Digest::MD5.hexdigest(SECURITY_KEY)
        str_before_md5 = target_str
        Digest::MD5.hexdigest(str_before_md5)
      end

      # apple支付证书更新流程
      # 1. 根据apple提示创建证书（Apple Pay Payment Processing Certificate）
      # 2. 本地导出private_key.p12
      # 3. openssl pkcs12 -in private_key.p12 -out apple_pay_cert.pem -clcerts -nokeys
      # 4. openssl pkcs12 -in private_key.p12 -out apple_pay_private_key.pem -nocerts -nodes
      # 5. 将apple_pay_cert.pem apple_pay_private_key.pem上传到服务器
      # 6. 支付第一次可能会失败，证书还没生效，多试几次
      def decrypt_payment_token(token_attrs)
        logger.debug("Apple Pay token_attrs is: #{token_attrs}")
        token = Gala::PaymentToken.new(token_attrs)
        certificate_pem = File.read(Rails.root.join("config/apple_pay_cert.pem"))
        private_key_pem = File.read(Rails.root.join("config/apple_pay_private_key.pem"))
        token.decrypt(certificate_pem, private_key_pem)
      end

      def get_card_transation_data(emv_data)
        "{ICCardData=#{emv_data}&carrierAppTp=2&carrierTp=6}"
      end

      def get_customer_info(encrypted_pin_data, cardholder_name)
        # TODO: 需要测如果cardholder_name不存在的情况要不要传customerNm
        str = "{customerNm=#{cardholder_name}&pin=#{encrypted_pin_data}}"
        Base64.encode64(str).gsub("\n", "")
      end
    end
  end
end
