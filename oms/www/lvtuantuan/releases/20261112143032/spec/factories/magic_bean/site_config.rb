# frozen_string_literal: true

FactoryBot.define do
  factory :site_config, class: "MagicBean::SiteConfig" do
    return_receiver_properties { {
      receiver_name: "黄xx",
      tel_number: "13800138000",
      full_receiver_address: "华强路9号保利克洛维大厦中盈1110"
    } }
    customer_service_name { "eBest" }
    integral_rules { {
      sign_up_integral: 500,
      suggest_integral: 500,
      inviting_integral: 500,
      integral_received_from_one_yuan: 1,
      integral_deducted_from_one_yuan: 100,
      max_integral_in_one_order: 2000
    } }
    direct_refund_reasons { ["我不想要了"] }
    after_sale_reasons { ["7天无理由退货", "颜色/图案/款式与描述不符"] }
    mall_tips { {
      shop_cart_tips: "全场商品8.8折, 16：00前付款当天发货"
    } }
    member_bg_image { "https://picsum.photos/1024/480/?image=55" }
    payment_settings { {
      wechat_service_percentage: 1,
      vm_credit_card_service_percentage: 1,
      exchange_rate_rise_percentage: 1,
      unionpay_credit_card_service_percentage: 1,
      credit_card_enable: true,
      omipay_wechat_service_percentage: 1,
      omipay_alipay_service_percentage: 1
    } }
    cutoff_time { [{ time: "22:45", earliest_delivery_time: "08:00-12:00", time_kind: "next_day" }] }
  end
end
