# frozen_string_literal: true
module BeansAdmin::API::Entities
  class CouponPackage < ::CommonEntities::Model
    expose :name
    expose :code
    expose :status
    expose :user_kind
    expose :coupon_template_ids
    expose :cover
    expose :start_at
    expose :end_at
    expose :coupon_templates_info
  end
end
