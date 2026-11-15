# frozen_string_literal: true

module BeansApp::API::Entities
  class Order < SimpleOrder
    expose :paid_at
    expose :finished_at, if: lambda { |instance, _| instance.trade_finished? }
    expose :receiver_properties
    expose :buyer_message
    expose :cancel_reason
    expose :delivered_at
    expose :confirmed_at
    expose :latest_payment_time, documentation: { desc: "最迟支付时间" }, if: lambda { |instance, _| instance.wait_buyer_pay? }
    expose :latest_confirm_time, documentation: { desc: "最迟确认时间" }, if: lambda { |instance, _| instance.wait_buyer_confirm_goods? }
    # expose :invoicable_amount_in_yuan
    expose :coupon, using: BeansApp::API::Entities::Coupon, if: lambda { |instance, _| instance.is_a?(MagicBean::NormalOrder) }
    expose :gift_card_coupon, using: BeansApp::API::Entities::GiftCardCoupon
    expose :groupon, using: BeansApp::API::Entities::SimpleGroupon, if: lambda { |instance, _| instance.is_a?(MagicBean::GrouponOrder) }
    # expose :invoice_id,  documentation: { type: Integer, desc: "发票ID" }
    expose :effective_refund_amount_in_cent, as: :successful_refund_amount_in_cent
    expose :effective_refund_integral_amount_in_cent, as: :successful_refund_integral_amount_in_cent
    expose :effective_after_sales_order_items_quantity, as: :successful_after_sales_order_items_quantity
    expose :scene_code
    expose :self_pick_up, using: BeansApp::API::Entities::SelfPickUp
    expose :union_pay_response_hash, as: :union_pay_response, if: lambda { |instance, options| options[:need_response] && instance.union_pay? }
    expose :reward_integral_amount, as: :reward_integral
    expose :payment_info_hash
    expose :gst_amount_in_yuan, documentation: { desc: "GST税金" }
    expose :has_other_parent_orders
    expose :cancel_paid_parent_order_notice do |order|
      order.admin_multi_lang_config(I18n.locale.to_s)&.cancel_paid_parent_order_notice
    end

    def union_pay_response_hash
      response = object.union_pay_response

      { resp_code: response["respCode"], query_result: response["queryResult"], resp_msg: response["respMsg"] }
    end

    def payment_info_hash
      case object.payment_type
      when "wechat"
        { type: MagicBean::OmipayPayment::WECHAT_PLATFORM.downcase, text: I18n.t("attributes.payment_types.wechat") }
      when "omipay"
        { type: object.omipay_platform&.downcase, text: object.omipay_platform&.include?("WECHAT") ? I18n.t("attributes.payment_types.wechat") : I18n.t("attributes.payment_types.alipay")}
      when "supay"
        { type: object.supay_platform&.downcase, text: object.supay_platform&.include?("WXPAY") ? I18n.t("attributes.payment_types.wechat") : I18n.t("attributes.payment_types.alipay")}
      when "credit_card"
        response = object.completed_charge_payment&.response
        if response.present?
          # brand: ["visa", "mastercard"]
          card = response["sourceOfFunds"]["provided"]["card"]
          { type: card["brand"].downcase, text: "#{I18n.t("attributes.payment_types.credit_card")}#{card["number"].last(8).gsub("x", "*")}" }
        else
          { type: nil, text: nil }
        end
      when "union_pay"
        { type: object.payment_type, text: I18n.t("attributes.payment_types.union_pay") }
      when "apple_pay"
        { type: object.payment_type, text: I18n.t("attributes.payment_types.apple_pay") }
      when "cba_apple_pay"
        { type: object.payment_type, text: I18n.t("attributes.payment_types.cba_apple_pay") }
      when "cba_google_pay"
        { type: object.payment_type, text: I18n.t("attributes.payment_types.cba_google_pay") }
      when "stripe_credit_card"
        { type: object.payment_type, text: I18n.t("attributes.payment_types.credit_card") }
      when "stripe_google_pay"
        { type: object.payment_type, text: I18n.t("attributes.payment_types.stripe_google_pay") }
      when "stripe_apple_pay"
        { type: object.payment_type, text: I18n.t("attributes.payment_types.stripe_apple_pay") }
      else
        { type: nil, text: nil }
      end
    end

    # 用于app母单退款判断是否弹窗，has_other_parent_orders为false会弹窗
    # 本身为母单，不存在其他母单，且有子单的情况弹窗，其他情况都不弹窗
    def has_other_parent_orders
      object.is_child || object.has_other_parent_orders? || object.child_orders.blank?
    end
  end
end
