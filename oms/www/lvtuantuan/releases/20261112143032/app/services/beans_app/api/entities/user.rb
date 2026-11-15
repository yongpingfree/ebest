# frozen_string_literal: true

module BeansApp::API::Entities
  class User < SimpleUser
    expose :mobile
    expose :new_user?, as: :is_new_user, documentation: { type: Grape::API::Boolean }
    expose :gender, documentation: { type: Integer } do |object|
      ::MagicBean::User.genders[object.origin_gender.presence || object.gender]
    end
    expose :is_host, documentation: { desc: "用户是否主播" }
    expose :like_items_count, documentation: { type: Integer, desc: "收藏商品数量" }
    expose :wait_buyer_pay_orders_count, documentation: { type: Integer, desc: "待发货订单数量" }
    expose :wait_seller_send_goods_count, documentation: { type: Integer, desc: "待发货订单数量" }
    expose :wait_buyer_confirm_goods_count, documentation: { type: Integer, desc: "待收货订单数量" }
    expose :locale, documentation: { type: String, desc: "语言设置" }
    expose :after_sales_count, documentation: { type: Integer, desc: "退款售后数量" }
    expose :items_viewed_count, documentation: { type: Integer, desc: "足迹（浏览商品）数" }
    expose :is_overseas_student
    expose :member, using: BeansApp::API::Entities::Member
    expose :bind_wechat do |object|
      object.ebest_platform_unionid?
    end
    expose :has_password?, as: :has_password
  end
end
