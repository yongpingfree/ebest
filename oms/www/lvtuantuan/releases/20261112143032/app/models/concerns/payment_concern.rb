# frozen_string_literal: true

require "credit_card_validations/string"

module PaymentConcern
  extend ActiveSupport::Concern

  @@stripe_logger = ::Logger.new("./log/stripe.log")
  @@union_pay_logger = ::Logger.new("./log/union_pay.log")
  @@apple_pay_logger = ::Logger.new("./log/apple_pay.log")

  # 支付成功统一方法
  def pay_success(transaction_id, paid_at)
    transaction do
      if wait_buyer_pay? || risk_pay?
        perform_aasm_event(:pay)
        update({
          transaction_id: transaction_id,
          paid_at: paid_at,
          payment_in_progress: false
        })
      end
    end
  end

  # raw_xml:
  # {
  #   "return_code"=>"SUCCESS",
  #   "return_msg"=>"OK",
  #   "appid"=>"",
  #   "mch_id"=>"",
  #   "nonce_str"=>"ACXcF0ef6w3Qauo2",
  #   "sign"=>"EE10FA7FF241ED75032EE09841296CD0",
  #   "result_code"=>"SUCCESS",
  #   "prepay_id"=>"wx09153735462182e3a0e21c502916449545",
  #   "trade_type"=>"JSAPI"
  # }
  def request_wechat_payment(ebest_channel)
    WxPay.logger.info("unifiedorder for order: #{id}")
    unifiedorder = WxPay::Service.invoke_unifiedorder unifiedorder_params
    raw_xml = unifiedorder.dig(:raw, "xml")
    if unifiedorder.success?
      js_payment_params = {
        prepayid: raw_xml["prepay_id"],
        noncestr: raw_xml["nonce_str"]
      }
      update_prepay_id(js_payment_params[:prepayid], ebest_channel)
      WxPay.logger.info("generate_js_pay_req for order: #{id}")
      result = WxPay::Service.generate_js_pay_req js_payment_params
      { status: "success", data: result }
    else
      WxPay.logger.error("unifiedorder result: #{unifiedorder}")
      { status: "fail", msg: raw_xml["err_code_des"] }
    end
  rescue RestClient::Exceptions::Timeout
    WxPay.logger.error("连接超时")
    raise RestClient::Exceptions::Timeout
  end

  # official document for detailed request params and return fields
  # https://pay.weixin.qq.com/wiki/doc/api/app/app.php?chapter=9_1
  def unifiedorder_params
    {
      body: "eBest-订单支付",
      out_trade_no: no,
      total_fee: wechat_payment_in_cent,
      spbill_create_ip: ip_address,
      notify_url: Rails.application.credentials.dig(Rails.env.to_sym, :wechat, :pay_notify_url),
      trade_type: "JSAPI",
      openid: user.open_id
    }
  end

  def enqueue_refund_job(refund_amount = nil)
    if payment_in_cent_eql_zero?
      drawback!
    else
      generate_refund_no
      self.save
      # 订单只会有一个成功的支付, 订单退运费 refund_freight = true
      # 整单退款需要退手续费、箱规费用
      # 跨境购订单不退运费，但如果是同步失败退款（ae_order_list为空说明同步失败），需要退运费
      if ae_drop_shipper
        ae_order_create_failed = ae_order_list.blank?
        refund_freight = ae_order_create_failed
        refund_box_regulation_fee = ae_order_create_failed
        refund_package_service_fee = ae_order_create_failed
      else
        refund_freight = true
        refund_box_regulation_fee = true
        refund_package_service_fee = true
      end
      completed_charge_payment&.generate_refund_payment(refund_amount, self, refund_freight, true, refund_box_regulation_fee, refund_package_service_fee)
    end
  end

  # refund_fee 直接取 payment 中已经算好的 amount
  def wechat_refund_params
    {
      out_trade_no: no,
      out_refund_no: no + "o", # 订单退款号增加一位，与AfterSale退款区分开,
      total_fee: wechat_payment_in_cent,
      notify_url: Rails.application.credentials.dig(Rails.env.to_sym, :wechat, :refund_notify_url)
    }
  end

  def card_pretreatment(card)
    card_number = card[:number]&.gsub(/\s+/, "")
    card_exp_month = card[:exp_month]&.gsub(/\s+/, "")
    card_exp_year = card[:exp_year]&.gsub(/\s+/, "")
    card_cvc = card[:cvc]&.gsub(/\s+/, "")

    [card_number, card_exp_year, card_exp_month, card_cvc]
  end

  def request_union_pay_payment(ebest_channel, card, email = nil)
    @@union_pay_logger.info("pay for order: #{id}")

    return [false, "卡信息不能为空"] if card.blank?

    card_number, card_exp_year, card_exp_month, card_cvc = card_pretreatment(card)

    return [false, "请补全卡信息"] if card_number.blank? || card_exp_month.blank? || card_exp_year.blank? || card_cvc.blank?

    # 3 -> 03
    if card_exp_month.length < 2
      card_exp_month = "0#{card_exp_month}"
    end

    return [false, "请输入正确的月份"] unless card_exp_month.to_i.between?(1, 12)
    return [false, "所填年月已经过期"] if Date.new("20#{card_exp_year}".to_i, card_exp_month.to_i) < Date.current

    return [false, "请输入正确类型的卡号"] if !card_number.valid_credit_card_brand?(:unionpay)

    transaction do
      if no_transaction_fee?
        self.credit_card_payment_in_cent = payment_in_cent
        self.credit_card_service_percentage = 0
      else
        self.credit_card_payment_in_cent = unionpay_credit_card_payment_in_cent
        self.credit_card_service_percentage = unionpay_credit_card_service_percentage
      end

      self.save

      options = {
        orderTime: Time.use_zone("Beijing") { Time.current }.strftime("%Y%m%d%H%M%S"),
        orderCurrency: "036", # AUD - 036
        orderNumber: no,
        orderAmount: credit_card_payment_in_cent,
        acctNum: card_number,
        cardExpiredDate: "#{card_exp_year}#{card_exp_month}",
        cardCvn2: card_cvc,
        customerIp: ip_address,
        transType: UnionPay::Payment::TRANS_TYPE[:purchase]
      }

      resp = UnionPay::Payment.transaction(options)

      return [false, "交易失败"] unless resp.present?

      resp_code = resp["respCode"]
      resp_msg = resp["respMsg"]
      if resp_code == "00"

        # 此处仅表示交易受理成功，不代表支付成功
        @@union_pay_logger.info("pay for order success: #{id}")

        payment = MagicBean::UnionPayPayment.find_or_create_charge_from_webhook(self, resp, ebest_channel)
        [true]
      else
        # 如果支付失败需要重新生成唯一订单号
        regenerate_order_no
        @@union_pay_logger.error("pay for order failure: #{id}, #{resp}")
        [false, resp_msg || "交易失败"]
      end
    end
  end

  def request_stripe_payment(card, email, ebest_channel)
    @@stripe_logger.info("pay for order: #{id}")

    return [false, "卡信息不能为空"] if card.blank?

    card_number = card[:number]&.gsub(/\s+/, "")

    return [false, "请输入正确类型的卡号"] if (card[:type] == "vm" && !card_number.valid_credit_card_brand?(:mastercard, :visa)) ||
      (card[:type] == "unionpay" && !card_number.valid_credit_card_brand?(:unionpay))

    card_exp_month = card[:exp_month]&.gsub(/\s+/, "")
    card_exp_year = card[:exp_year]&.gsub(/\s+/, "")
    card_cvc = card[:cvc]&.gsub(/\s+/, "")

    token = Stripe::Token.create({
      card: {
        exp_month: card_exp_month,
        exp_year: card_exp_year,
        number: card_number,
        cvc: card_cvc
      },
    })

    transaction do

      if no_transaction_fee?
        self.credit_card_payment_in_cent = payment_in_cent
        self.credit_card_service_percentage = 0
      else
        self.credit_card_payment_in_cent = send "#{card[:type]}_credit_card_payment_in_cent"
        self.credit_card_service_percentage = send "#{card[:type]}_credit_card_service_percentage"
      end

      self.save

      # idempotency_key = "#{no}-#{card_number.last(4)}-#{card_exp_month}-#{card_exp_year}-#{card_cvc}"

      charge_params = {
        amount: credit_card_payment_in_cent,
        currency: "aud",
        description: "商品订单支付",
        source: token,
        metadata: {
          order_id: id
        }
      }

      charge_params[:receipt_email] = email if email.present?
      resp = Stripe::Charge.create(charge_params)

      if resp[:status] == "succeeded"
        @@stripe_logger.info("pay for order success: #{id}")
        payment = MagicBean::StripePayment.find_or_create_charge_from_webhook(self, resp, ebest_channel)
        pay_success(resp[:id], Time.zone.at(resp[:created]))

        [true]
      else
        @@stripe_logger.error("pay for order failure: #{id}, #{resp[:failure_message]}")
        [false, resp[:failure_message]]
      end
    end
  rescue Stripe::CardError, Stripe::RateLimitError, Stripe::InvalidRequestError, Stripe::AuthenticationError,
    Stripe::APIConnectionError, Stripe::StripeError  => e
    @@stripe_logger.error("pay for order failure: #{id}, #{e.message}(#{e.code})")

    [false, I18n.t("stripe.errors.#{e.code}", default: e.message)]
  end

  def make_omipay_app_order(platform)
    data = {
      amount: omipay_pay_amount_in_cent(platform),
      order_name: order_name,
      out_order_no: no,
      platform: platform,
      notify_url: "#{Rails.application.credentials.dig(Rails.env.to_sym, :domain)}/orders/omipay_notify",
      currency: "AUD"
    }

    data[:app_id] = Rails.application.credentials.dig(Rails.env.to_sym, :wechat)[:mobile_app_id] if platform == MagicBean::OmipayPayment::WECHAT_PLATFORM

    Omipay::Api.make_app_order(data)
  end

  def make_omipay_aus_mp_order
    platform = MagicBean::OmipayPayment::WECHAT_PLATFORM

    data = {
      order_name: order_name,
      currency: "AUD",
      amount: omipay_pay_amount_in_cent(platform),
      notify_url: "#{Rails.application.credentials.dig(Rails.env.to_sym, :domain)}/orders/omipay_aus_mp_notify",
      out_order_no: no,
      platform: platform,
      app_id: Rails.application.credentials.dig(Rails.env.to_sym, :wechat_aus)[:app_id],
      customer_id: user_aus_mp_open_id
    }

    Omipay::Api.make_aus_mp_order(data)
  end

  def request_unionpay_apple_pay_payment(card_no, card_data)
    transaction do
      if no_transaction_fee?
        self.credit_card_payment_in_cent = payment_in_cent
        self.credit_card_service_percentage = 0
      else
        self.credit_card_payment_in_cent = apple_pay_payment_in_cent
        self.credit_card_service_percentage = apple_pay_service_percentage
      end
      self.save

      customer_info = ApplePay::Payment.get_customer_info(card_data["encryptedPINData"], card_data["cardholderName"])
      card_trans_data = ApplePay::Payment.get_card_transation_data(card_data["emvData"])
      order_time = Time.use_zone(MagicBean::ApplePayPayment::TIME_ZONE) { created_at }.strftime("%Y%m%d%H%M%S")

      options = {
        acctNum: card_no,
        cardTransData: card_trans_data,
        customerInfo: customer_info,
        orderAmount: credit_card_payment_in_cent, #交易金额 单位：分
        orderNumber: no, #订单号（需要商户自己生成）
        orderTime: order_time, #交易时间
        transType: ApplePay::Payment::TRANS_TYPE[:purchase]
      }

      # charset=UTF-8&cupReserved=&exchangeDate=&exchangeRate=&merId=620003620200007&orderAmount=1&orderCurrency=036&orderNumber=202002201645731991&payCardType=&qid=772112131741299774008&respCode=00&respMsg=Success%5B0000000%5D&settleAmount=&settleCurrency=&settleDate=&signMethod=md5&signature=e27b01a67beafd75f4d76854f33cae17&traceNumber=&traceTime=&transType=01&version=5.0.0
      resp = ApplePay::Payment.transaction(options)
      return [false, "交易失败"] unless resp.present?

      resp_code = resp["respCode"]
      resp_msg = resp["respMsg"]

      # 32是银联测试环境的问题，返回32是已经到银联端，通的了
      if resp_code.in?(["00", "32"])
        # 此处仅表示交易受理成功，不代表支付成功
        @@apple_pay_logger.info("pay for order success: #{id}")

        MagicBean::ApplePayPayment.find_or_create_charge_from_webhook(self, resp, "app")
        [true]
      else
        # 如果支付失败需要重新生成唯一订单号
        regenerate_order_no
        @@apple_pay_logger.error("pay for order failure: #{id}, #{resp}")
        [false, resp_msg || "交易失败"]
      end
    end
  end

  def make_supay_app_order(platform)
    pay_amount = supay_pay_amount_in_yuan(platform)

    data = {
      service: "create_instant_trade",
      store_name: "eBest App",
      mch_order_no: no,
      pay_way: "SDK",
      pay_channel: platform,
      pay_amount: pay_amount,
      currency: "AUD",
      goods_name: no, # 用订单号作为goods_name
      goods_price: pay_amount,
      quantity: "1",
      goods_desc: "eBest goods",
      timeout_express: "1h" # 订单过期时间，虽然我们的订单是15分钟关闭，但避免异常情况，supay的交易设置1小时有效期
    }

    Supay::Api.make_app_order(data)
  end
end
