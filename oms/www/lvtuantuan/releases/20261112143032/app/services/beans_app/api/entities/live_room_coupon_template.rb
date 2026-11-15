# frozen_string_literal: true

module BeansApp::API::Entities
  class LiveRoomCouponTemplate < ::CommonEntities::Model
    expose :coupon_template, using: BeansApp::API::Entities::CouponTemplate
  end
end
