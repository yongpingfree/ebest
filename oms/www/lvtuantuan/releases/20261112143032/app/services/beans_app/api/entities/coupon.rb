# frozen_string_literal: true

module BeansApp::API::Entities
  class Coupon < ::CommonEntities::Model
    expose :coupon_template_title, as: :title, documentation: { desc: "名字" }
    expose :details_image, documentation: { desc: "详情页封面" }
    expose :expired_image, documentation: { desc: "过期后封面" }
    expose :ticket_image, documentation: { desc: "封面" }
    expose :code, documentation: { desc: "代码" }
    expose :start_at, documentation: { desc: "开始时间（可以开始使用优惠券）" }
    expose :expired_at, documentation: { desc: "结束时间（不能再使用优惠券）" }
    expose :status, documentation: { desc: "状态" }
    expose :usable?, as: :usable, documentation: { desc: "是否可用" }
    expose :item_ids, documentation: { desc: "产品ID" }
    expose :category_ids, documentation: { desc: "一级分类ID" }
    expose :sub_category_ids, documentation: { desc: "二级分类ID" }
    expose :brand_ids, documentation: { desc: "品牌ID" }
    expose :kind, documentation: { desc: "类型" }
    expose :target_kind, documentation: { desc: "作用类型" }
    expose :discount, documentation: { desc: "折扣" }
    expose :denominations_in_cent, documentation: { desc: "优惠券面额，单位：分" }
    expose :at_least_amount_in_cent, documentation: { desc: "门槛金额，单位：分" } do |instance, _|
      instance.at_least_amount_in_cent.to_i
    end
    expose :instruction
    expose :channel, documentation: { type: String, values: ->() { MagicBean::Coupon.channels.keys }, desc: "平台类型" }
    expose :store, using: BeansApp::API::Entities::Store
    expose :delivery_types
    expose :payment_types
  end
end
