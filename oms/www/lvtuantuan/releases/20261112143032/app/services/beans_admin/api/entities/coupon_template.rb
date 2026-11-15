# frozen_string_literal: true

module BeansAdmin::API::Entities
  class CouponTemplate < SimpleCouponTemplate
    expose :desc, documentation: { desc: "说明" }
    expose :denominations_in_cent, documentation: { type: Integer, desc: "面额（单位：分）" }
    expose :at_least_amount_in_cent, documentation: { type: Integer, desc: "订单满减金额"}
    expose :denominations_in_yuan, documentation: { type: Integer, desc: "面额（单位：元）" }
    expose :min_denominations_in_cent
    expose :min_denominations_in_yuan
    expose :max_denominations_in_cent
    expose :max_denominations_in_yuan
    expose :discount, documentation: { type: Float, desc: "折扣" }
    expose :details_image, documentation: { desc: "详情页封面" }
    expose :expired_image, documentation: { desc: "过期后封面" }
    expose :ticket_image, documentation: { desc: "封面" }
    expose :code, documentation: { desc: "代码" }
    expose :mini_program_path, documentation: { desc: "小程序路径" }
    expose :can_edit?, as: :can_edit
    expose :category_ids, documentation: { desc: "一级分类ID" }
    expose :categories, documentation: { desc: "一级分类" }
    expose :sub_category_ids, documentation: { desc: "二级分类ID" }
    expose :sub_categories, documentation: { desc: "二级分类" }
    expose :brand_ids, documentation: { desc: "品牌ID" }
    expose :brands, documentation: { desc: "品牌" }
    expose :random_reduction_coupon_template_rules, using: RandomReductionCouponTemplateRule
  end
end
