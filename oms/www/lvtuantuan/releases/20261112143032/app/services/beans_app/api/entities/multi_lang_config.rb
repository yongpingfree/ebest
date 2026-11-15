# frozen_string_literal: true

module BeansApp::API::Entities
  class MultiLangConfig < Grape::Entity
    expose :order_buyer_message_placeholder, documentation: { desc: "下单页买家留言提示文字" }
    expose :ae_order_buyer_message_placeholder, documentation: { desc: "跨境购下单页买家留言提示文字" }
    expose :shopping_cart_page_top_tips, documentation: { desc: "购物车顶部提示" }
    expose :ae_shopping_cart_page_top_tips, documentation: { desc: "跨境购购物车顶部提示" }
    expose :payment_wechat_note, documentation: { desc: "小程序微信支付Note" }
    expose :payment_omipay_wechat_note, documentation: { desc: "Omipay微信支付Note" }
    expose :payment_omipay_alipay_note, documentation: { desc: "Omipay支付宝支付Note" }
    expose :payment_supay_wechat_note, documentation: { desc: "Supay微信支付Note" }
    expose :payment_supay_alipay_note, documentation: { desc: "Supay支付宝支付Note" }
    expose :payment_commweb_note, documentation: { desc: "VISA/MASTER信用卡支付Note" }
    expose :payment_unionpay_note, documentation: { desc: "银联支付Note" }
    expose :payment_apple_pay_note, documentation: { desc: "银联ApplePay Note" }
    expose :payment_cba_apple_pay_note, documentation: { desc: "CBA ApplePay Note" }
    expose :payment_cba_google_pay_note, documentation: { desc: "CBA GooglePay Note" }
    expose :payment_stripe_credit_card_note, documentation: { desc: "Stripe信用卡支付" }
    expose :payment_stripe_apple_pay_note, documentation: { desc: "Stripe ApplePay支付" }
    expose :payment_stripe_google_pay_note, documentation: { desc: "Stripe GooglePay支付" }
    expose :direct_refund_reasons, documentation: { desc: "取消订单退款理由，App 端需切割成数组" }
    expose :after_sale_reasons, documentation: { desc: "申请售后理由，App 端需切割成数组" }
    expose :checkout_merchant_delivery_remark, documentation: { desc: "送货上门备注" }
    expose :checkout_self_pick_remark, documentation: { desc: "自提备注" }
    expose :checkout_express_remark, documentation: { desc: "邮寄备注" }
    expose :header_search_bar_placeholder, documentation: { desc: "页面顶部搜索栏提示文字" }
    expose :web_homepage_top_notice, documentation: { desc: "英文网站首页顶部公告" }
    expose :refer_friend_clipboard, documentation: { desc: "邀请用户剪贴板文案" }
    expose :refer_friend_title, documentation: { desc: "邀请用户标题" }
    expose :refer_friend_content, documentation: { desc: "邀请用户文字说明" }
    expose :registration_promo_text, documentation: { desc: "新用户注册奖励说明" }
    expose :place_ae_order_notice, documentation: { desc: "跨境购下单页弹窗" }
    expose :place_order_should_know, documentation: { desc: "下单页须知提示文字" }
    expose :place_order_merchant_delivery_top_tips, documentation: { desc: "确认订单信息顶部提示语(自派)" }
    expose :place_order_self_pick_top_tips, documentation: { desc: "确认订单信息顶部提示语(自提)" }
    expose :place_order_express_top_tips, documentation: { desc: "确认订单信息顶部提示语(邮寄)" }
    expose :place_ae_order_top_tips, documentation: { desc: "确认订单信息顶部提示语(跨境购邮寄)" }
    expose :ae_order_gst_tip, documentation: { desc: "跨境购确认订单页GST提示语" }
    expose :order_value_added_service_fee_tip, documentation: { desc: "增值服务费说明" }
    expose :order_freight_fee_tip, documentation: { desc: "运费说明" }
    expose :order_authority_to_leave_house_name
    expose :order_authority_to_leave_apartment_name
    expose :order_authority_to_leave_office_name
    expose :order_delivered_in_person_house_name
    expose :order_delivered_in_person_apartment_name
    expose :order_delivered_in_person_office_name
    expose :order_deliver_to_door_house_name
    expose :order_deliver_to_door_apartment_name
    expose :order_deliver_to_door_office_name
    expose :order_authority_to_leave_hourse_tip
    expose :order_authority_to_leave_apartment_tip
    expose :order_authority_to_leave_office_tip
    expose :order_delivered_in_person_house_tip
    expose :order_delivered_in_person_apartment_tip
    expose :order_delivered_in_person_office_tip

    def payment_commweb_note
      order = options[:order]
      if order
        object.payment_commweb_note&.gsub("{amex_amount}", order.amex_credit_card_service_amount_in_cent.to_s)
      else
        object.payment_commweb_note
      end
    end
  end
end
