# frozen_string_literal: true

module BeansApp::API::Entities
  class CouponPackage < ::CommonEntities::Model
    expose :name, documentation: { desc: "名字" }
    expose :code, documentation: { desc: "代码" }
    expose :cover, documentation: { desc: "封面" }
    expose :coupon_count, documentation: { desc: "优惠券数量" }
    expose :user_kind
  end
end
