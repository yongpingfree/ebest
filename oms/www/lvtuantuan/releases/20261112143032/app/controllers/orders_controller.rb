# frozen_string_literal: true

class OrdersController < ApplicationController
  include UsersHelper

  skip_before_action :verify_authenticity_token

  @@special_logger = ::Logger.new("./log/special_order_error.log")
  @@apple_pay_logger = ::Logger.new("./log/apple_pay.log")
  @@commweb_logger = ::Logger.new("./log/commweb.log")
  @@supay_logger = ::Logger.new("./log/supay.log")
  @@stripe_logger = ::Logger.new("./log/stripe.log")

  def notify
    result = Hash.from_xml(request.body.read)["xml"]
    if WxPay::Sign.verify?(result)
      order = MagicBean::Order.find_by!(no: result["out_trade_no"])

      payment = MagicBean::WechatPayment.find_or_create_charge_from_webhook(order, result)
      order.pay_success(
        result["transaction_id"],
        result["time_end"].in_time_zone(MagicBean::WechatPayment::TIME_ZONE)
      )
      render xml: {return_code: "SUCCESS"}.to_xml(root: "xml", dasherize: false)
    else
      render xml: {return_code: "FAIL", return_msg: "签名失败"}.to_xml(root: "xml", dasherize: false)
    end
  end

  def refund_notify
    encrypt_result = Hash.from_xml(request.body.read)["xml"]
    decrypt_result = Hash.from_xml(decrypt_data(encrypt_result["req_info"]))["root"]

    payment = MagicBean::Payment.find_by(transaction_id: decrypt_result["refund_id"])

    if payment.nil?
      WxPay.logger.error("payment refund notify error: #{decrypt_result}")
      raise ActiveRecord::RecordNotFound
    end
    WxPay.logger.info("refund notify payment id: #{payment.id}")

    if payment.pending? && decrypt_result["refund_status"] == "SUCCESS"
      payment.paymentable.drawback! if payment.paymentable&.refunding?
      payment.complete! if payment.may_complete?
      render xml: {return_code: "SUCCESS"}.to_xml(root: "xml", dasherize: false)
    end
  end

  def union_pay_params
    params.permit("charset", "cupReserved", "exchangeDate", "exchangeRate", "merId", "orderAmount", "orderCurrency", "orderNumber",
      "payCardType", "qid", "respCode", "respMsg", "settleAmount", "settleCurrency", "settleDate", "signMethod", "signature", "traceNumber",
      "traceTime", "transType", "version")
  end

  def union_pay_params_hash
    union_pay_params.to_h
  end

  def union_pay_notify
    if UnionPay::Payment::sign_verify?(union_pay_params_hash)
      if union_pay_params_hash["respCode"].eql?("00")
        if union_pay_params_hash["transType"].eql?("01")
          union_pay_pay_transation
        else
          union_pay_refund_transation
        end
      end
    else
      render json: { msg: "invalid signature" }, status: 401
    end
  end

  def union_pay_pay_transation
    order = MagicBean::Order.find_by(no: union_pay_params_hash["orderNumber"])
    trace_time = "#{Date.current.year}#{union_pay_params_hash["traceTime"]}".in_time_zone(MagicBean::UnionPayPayment::TIME_ZONE)
    if order && order.wait_buyer_pay?
      UnionPay::Payment.logger.info("pay for order success: #{order.id}, response: #{params}")
      payment = MagicBean::UnionPayPayment.find_or_create_charge_from_webhook(order, union_pay_params_hash, nil)
      payment.complete! if payment.pending?
      order.pay_success(
        union_pay_params_hash["qid"],
        trace_time
      )
    elsif order&.wait_seller_send_goods?
      payment = MagicBean::UnionPayPayment.find_or_create_charge_from_webhook(order, union_pay_params_hash, nil)
      order.update(paid_at: trace_time)
    end
  end

  def union_pay_refund_transation
    payment = MagicBean::Payment.find_by(no: union_pay_params_hash["orderNumber"])
    UnionPayQueryJob.set(wait: 5.seconds).perform_later(payment.id)
    if payment.nil?
      UnionPay::Payment.logger.error("payment refund notify error: #{decrypt_result}")
      raise ActiveRecord::RecordNotFound
    end
    UnionPay::Payment.logger.info("refund notify payment id: #{payment.id}")

    payment.update_and_paymentable_refund(union_pay_params_hash)
  end

  # omipay app 支付回调
  def omipay_notify
    result = JSON.parse(request.body.read)

    if Omipay::Api.verify?(result)
      order = MagicBean::Order.find_by!(no: result["out_order_no"])

      payment = MagicBean::OmipayPayment.find_or_create_charge_from_webhook(order, result, "app")

      if order.trade_closed?
        OrderMailer.with(order_no: order.no).order_close_before_omipay_callback.deliver_later

        if payment.payments.refund_payment_type.blank?
          order.send(:generate_refund_no)
          order.save(validate: false)
          # 触发退款，已经退款的payment不再重复触发
          payment.generate_refund_payment(payment.amount_in_cent, order, true, true, true, true)
        end
      else
        order.pay_success(
          payment.transaction_id,
          result["pay_time"].in_time_zone(MagicBean::OmipayPayment::TIME_ZONE)
        )
      end

      render json: { return_code: "SUCCESS" }
    else
      render json: { return_code: "FAIL" }
    end
  end

  def omipay_aus_mp_notify
    result = JSON.parse(request.body.read)

    if Omipay::Api.verify?(result)
      order = MagicBean::Order.find_by!(no: result["out_order_no"])

      payment = MagicBean::OmipayPayment.find_or_create_charge_from_webhook(order, result, "mini_program")

      if order.trade_closed?
        OrderMailer.with(order_no: order.no).order_close_before_omipay_callback.deliver_later
        if payment.payments.refund_payment_type.blank?
          order.send(:generate_refund_no)
          order.save(validate: false)
          # 触发退款，已经退款的payment不再重复触发
          payment.generate_refund_payment(payment.amount_in_cent, order, true, true, true, true)
        end
      else
        order.pay_success(
          payment.transaction_id,
          result["pay_time"].in_time_zone(MagicBean::OmipayPayment::TIME_ZONE)
        )
      end

      render json: { return_code: "SUCCESS" }
    else
      render json: { return_code: "FAIL" }
    end
  end

  # params
  # {"notify_id"=>"2023020800784221336078782464",
  #  "notify_type"=>"trade_status_sync",
  #  "notify_time"=>"20230208180928",
  #  "_input_charset"=>"utf-8",
  #  "sign_type"=>"MD5",
  #  "version"=>"1.0",
  #  "outer_trade_no"=>"S202302030904433207",
  #  "inner_trade_no"=>"185058659704421020",
  #  "trade_status"=>"TRADE_SUCCESS",
  #  "trade_amount"=>"0.01",
  #  "sign"=>"25C92AC96371EE1991AC006725EC66CD",
  #  "controller"=>"orders",
  #  "action"=>"supay_notify"}
  def supay_notify
    # 先把请求过来的数据记录到日志
    @@supay_logger.debug("Supay notify params: #{params.to_json}")
    result = JSON.parse(params.to_json)

    if Supay::Api.verify?(result)
      order = MagicBean::Order.find_by!(no: result["outer_trade_no"])
      # result缺少一些数据，需要重新获取order数据
      order.supay_order_handle

      render plain: "success"
    else
      render plain: "false"
    end
  end

  def commweb_checkout
    return render(json: { error_message: "401 Unauthorized" }, status: :unauthorized) unless current_user.present?
    return render(json: { error_message: "Missing parameter `order_id`" }, status: :bad_request) if params[:order_id].blank?

    set_locale
    order = current_user.orders.find(params[:order_id])

    unless order.may_pay?
      return render(:commweb_failure)
    end

    channel = params[:ebest_channel]&.strip == "web" ? "web" : "app"
    resp = order.hosted_checkout_session(channel)

    return render(:commweb_failure) if resp["msg"].present?

    # 避免下面更新transaction_id失败，所以先查一遍
    payment = MagicBean::CommwebPayment.find_by(paymentable: order, transaction_id: resp["successIndicator"], status: :pending, payment_type: :charge)

    # 获取最后生成commweb payment, 不再每次都新建
    payment = MagicBean::CommwebPayment.order(id: :desc).find_or_initialize_by({
      paymentable: order,
      status: :pending,
      payment_type: :charge
    }) unless payment

    payment.update(
      transaction_id: resp["successIndicator"],
      amount_in_cent: order.credit_card_payment_in_cent,
      channel: channel,
      response: resp
    )

    @checkout_config = {
      session: {
        id: resp["session"]["id"]
      },
      interaction: {
        merchant: {
          name: "eBest"
        },
        operation: "PURCHASE"
      },
      merchant: resp["merchant"],
      order: {
        id: order.no,
        amount: order.payment_in_yuan_num,
        currency: "AUD",
        description: "eBest payment"
      }
    }
  end

  def commweb_notify
    @@commweb_logger.debug("Commweb notify: #{params.to_json}")
    payment = MagicBean::CommwebPayment.find_by transaction_id: params[:resultIndicator]
    order = payment.paymentable
    resp = Commweb::Payment.retrieve_order(order.no, payment.channel)

    risk_resp = resp["risk"]
    if order.risk_pay_enabled && risk_resp.present? && risk_resp["response"]["gatewayCode"] == "REVIEW_REQUIRED" && risk_resp["response"]["review"]["decision"].upcase != "ACCEPTED"
      if risk_resp["response"]["review"]["decision"].upcase == "PENDING"
        # 等待审核
        order.risk! if order.wait_buyer_pay?

        if order.trade_closed?
          # 风险支付只通知管理员，不退款
          OrderMailer.with(order_no: order.no).order_close_before_cba_risk_callback.deliver_later
        end
      else
        # 审核不通过
        order.close!
        return render(:commweb_failure)
      end
    else
      # retrieve_order和retrieve_transaction返回结构不同，retrieve_order要判断status，retrieve_transaction判断result
      if resp["status"] == "CAPTURED"
        total_captured_amount_in_cent = (resp["totalCapturedAmount"] * 100).round # 计算手续费后的总价
        net_amount_in_cent = order.payment_in_cent # 没计算手续费前的总价
        service_amount_in_cent = total_captured_amount_in_cent - net_amount_in_cent
        credit_card_percentage = (service_amount_in_cent * 100 / net_amount_in_cent.to_f).round(2)

        ActiveRecord::Base.transaction do
          payment.update!(
            response: resp,
            status: :completed,
            service_amount_in_cent: service_amount_in_cent,
            amount_in_cent: total_captured_amount_in_cent,
            completed_at: resp["lastUpdatedTime"].in_time_zone(MagicBean::CommwebPayment::TIME_ZONE)
          )

          order.set_order_items_service_amount(service_amount_in_cent)
          if order.trade_closed?
            order.update!(paid_at: payment.completed_at, final_amount_in_cent: total_captured_amount_in_cent,
                          credit_card_payment_in_cent: total_captured_amount_in_cent,
                          actual_credit_card_service_percentage: credit_card_percentage,
                          actual_credit_card_service_amount_in_cent: service_amount_in_cent,
                          integral_received_from_one_yuan: order.calculate_integral_received_from_one_yuan)
            
            OrderMailer.with(order_no: order.no).order_close_before_cba_callback.deliver_later

            if payment.payments.refund_payment_type.blank?
              order.send(:generate_refund_no)
              order.save(validate: false)
              # 触发退款，已经退款的payment不再重复触发
              payment.generate_refund_payment(payment.amount_in_cent, order, true, true, true, true)
            end
          else
            order.pay!
            order.update!(paid_at: payment.completed_at, final_amount_in_cent: total_captured_amount_in_cent,
                          credit_card_payment_in_cent: total_captured_amount_in_cent,
                          actual_credit_card_service_percentage: credit_card_percentage,
                          actual_credit_card_service_amount_in_cent: service_amount_in_cent)
          end
        end
      else
        return render(:commweb_failure)
      end
    end
  end

  def stripe_notify
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    event = nil
    endpoint_secret = Rails.application.credentials.dig(Rails.env.to_sym, :stripe, :webhook_secret)

    @@stripe_logger.debug("sig_header: #{sig_header}, payload: #{payload}")
    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )
    rescue JSON::ParserError => e
      render plain: "", status: 400
      return
    rescue Stripe::SignatureVerificationError => e
      render plain: "", status: 400
      return
    end

    case event.type
    when "payment_intent.succeeded"
      payment_intent = event.data.object
      order = MagicBean::Order.find_by(no: payment_intent.metadata["order_no"])
      payment_class_name = case payment_intent.metadata["type"]
        when "google_pay"
          "MagicBean::StripeGooglePayPayment"
        when "apple_pay"
          "MagicBean::StripeApplePayPayment" 
        else
          "MagicBean::StripePayment"
        end

      if order
        payment = payment_class_name.constantize.find_or_create_charge_from_intent_webhook(order, payment_intent, order.channel)

        if order.trade_closed?
          OrderMailer.with(order_no: order.no).order_close_before_stripe_callback.deliver_later

          if payment.payments.refund_payment_type.blank?
            order.send(:generate_refund_no)
            order.save(validate: false)
            # 触发退款，已经退款的payment不再重复触发
            payment.generate_refund_payment(payment.amount_in_cent, order, true, true, true, true)
          end
        else
          order.pay_success(
            payment.transaction_id,
            Time.zone.at(payment_intent["created"].to_i)
          )
        end
      end
    else
      @@stripe_logger.debug("Unhandled event type: #{event.type}, data: #{event&.data}")
    end

    render plain: "", status: 200
  end

  def commweb_failure
    set_locale
  end

  def order_invoice
    order = MagicBean::Order.find params[:order_id]
    render template: "order_invoice_mailer/invoice_pdf", layout: "mailer", locals: { order_invoice: order.order_invoice }
  end

  def apple_pay_notify
    # TODO: 先记录下回调数据，staging测试后再接着开发
    @@apple_pay_logger.debug("Apple Pay notify: #{params.to_json}")
    render json: { return_code: "SUCCESS" }
  end

  private

  # https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=9_16
  def decrypt_data(encrypted_base64)
    encrypted = Base64.decode64(encrypted_base64)
    decipher = OpenSSL::Cipher::AES256.new(:ECB)
    decipher.decrypt
    decipher.key = Digest::MD5.hexdigest(Rails.application.credentials.dig(Rails.env.to_sym, :wechat, :mch_key))
    data = decipher.update(encrypted) + decipher.final
    data
  end

  def set_locale
    I18n.locale = params[:locale].presence || current_user&.locale || I18n.default_locale
  end
end
