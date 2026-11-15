# frozen_string_literal: true

module BeansAdmin::API::Entities
  class Coupon < SimpleCoupon
    expose :desc, documentation: { desc: "说明" }
    expose :kind, documentation: { desc: "类型" }
    expose :status, documentation: { desc: "状态" }
    expose :denominations_in_cent, documentation: { type: Integer, desc: "面额（单位：分）" }
    expose :at_least_amount_in_cent, documentation: { type: Integer, desc: "订单满减金额"}
    expose :denominations_in_yuan, documentation: { type: Integer, desc: "面额（单位：元）" }
    expose :at_least_amount_in_yuan, documentation: { type: Integer, desc: "订单满减金额（单位：元）"}
    expose :discount, documentation: { type: Float, desc: "折扣" }
    expose :need_at_least_amount, documentation: { type: Grape::API::Boolean, desc: "是否无门槛使用"}
    expose :start_at, documentation: { desc: "开始时间（可以开始使用优惠券）" }
    expose :expired_at, documentation: { desc: "结束时间（不能再使用优惠券）" }
    expose :details_image, documentation: { desc: "详情页封面" }
    expose :expired_image, documentation: { desc: "过期后封面" }
    expose :ticket_image, documentation: { desc: "封面" }
    expose :code, documentation: { desc: "代码" }
    expose :user, using: BeansAdmin::API::Entities::SimpleUser
    expose :order_no, documentation: { desc: "订单no" }
    expose :order_id, documentation: { desc: "订单ID" }
    expose :order_type, documentation: { desc: "订单类型" }
    expose :item_ids, documentation: { desc: "产品ID" }
    expose :qrcode, documentation: { desc: "优惠券码" }
    expose :channel, documentation: { type: String, values: ->() { MagicBean::CouponTemplate.channels.keys }, desc: "平台类型" }
    expose :destroyable?, as: :destroyable
  end
end
