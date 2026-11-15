# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleCouponTemplate < ::CommonEntities::Model
    expose :title, documentation: { desc: "名字" }
    expose :title_with_store
    translate_expose :title, documentation: { desc: "名字" }
    expose :kind, documentation: { type: String, values: ->() { MagicBean::CouponTemplate.kinds.keys }, desc: "类型" }
    expose :enabled, documentation: { type: Grape::API::Boolean, desc: "是否启用优惠券"}
    expose :display_in_item_detail, documentation: { type: Grape::API::Boolean, desc: "是否展示在产品详情页"}
    expose :qrcode
    expose :target_kind, documentation: { type: String, values: ->() { MagicBean::CouponTemplate.target_kinds.keys }, desc: "用券对象" }
    expose :time_kind, documentation: { type: String, values: ->() { MagicBean::CouponTemplate.time_kinds.keys }, desc: "用券时间类型" }
    expose :user_kind, documentation: { type: String, values: ->() { MagicBean::CouponTemplate.user_kinds.keys }, desc: "用户类型" }
    expose :usage_kind, documentation: { type: String, values: ->() { MagicBean::CouponTemplate.usage_kinds.keys }, desc: "用途" }
    expose :cost_accounting, documentation: { type: String, values: ->() { MagicBean::CouponTemplate.cost_accountings.keys }, desc: "成本核算" }
    expose :need_at_least_amount, documentation: { type: Grape::API::Boolean, desc: "是否无门槛使用"}
    expose :at_least_amount_in_yuan, documentation: { type: Integer, desc: "订单满减金额（单位：元）"}
    expose :time_limit_in_day, documentation: { type: Integer, desc: "领取后限时使用 0 表示无限" }
    expose :start_at, documentation: { desc: "开始时间（可以开始使用优惠券）" }
    expose :end_at, documentation: { desc: "结束时间（不能再使用优惠券）" }
    expose :remarks, documentation: { desc: "备注" }
    expose :coupons_count, documentation: { type: Integer, desc: "优惠券总数" }
    # expose :users_count, documentation: { type: Integer, desc: "已领取数" }
    # expose :orders_count, documentation: { type: Integer, desc: "已使用优惠券数" }
    expose :assigned_count, as: :users_count
    expose :used_count, as: :orders_count
    expose :avaliable_coupons_count, documentation: { type: Integer, desc: "可用优惠券数" }
    expose :item_ids, documentation: { desc: "产品ID" }
    expose :template_items, as: :items, using: BeansAdmin::API::Entities::MinimalItem, documentation: { desc: "可优惠产品" }
    expose :channel, documentation: { type: String, values: ->() { MagicBean::CouponTemplate.channels.keys }, desc: "平台类型" }
    expose :delivery_types, documentation: { type: Array[String], values: MagicBean::Order.delivery_types.keys, desc: "配送类型" }
    expose :payment_types, documentation: { type: Array[String], values: %w(omipay_wechat omipay_alipay supay_wechat supay_alipay credit_card union_pay apple_pay cba_apple_pay cba_google_pay stripe_credit_card stripe_google_pay stripe_apple_pay), desc: "支付类型" }
    expose :party, documentation: { type: String, values: %w(ebest_inside ebest_outside), desc: "发券方" }
    expose :store_name
    expose :assign_start_at
    expose :assign_end_at
    expose :assign_total_quantity
    expose :custom_list_ids, documentation: { desc: "自定义产品列表ID" }
    expose :template_custom_lists, as: :custom_lists, using: BeansAdmin::API::Entities::SimpleCustomList, documentation: { desc: "可优惠产品" }
    expose :max_random_reduction_count

    def assigned_count
      object.respond_to?(:assigned_count) ? object.assigned_count : object.users_count
    end

    def used_count
      object.respond_to?(:used_count) ? object.used_count : object.orders_count
    end

    def template_items
      object.item_ids.present? ? object.items : []
    end

    def store_name
      object.store_id? ? object.store&.name : "全店通用"
    end

    def template_custom_lists
      object.custom_list_ids.present? ? object.custom_lists : []
    end
  end
end
