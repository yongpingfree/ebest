# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleCoupon < ::CommonEntities::Model
    expose :coupon_template_title, as: :title
    expose :coupon_template_id, documentation: { type: Integer, desc: "优惠券模板ID" }
  end
end
