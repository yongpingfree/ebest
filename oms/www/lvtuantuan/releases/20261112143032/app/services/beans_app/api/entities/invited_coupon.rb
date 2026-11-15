# frozen_string_literal: true

module BeansApp::API::Entities
  class InvitedCoupon < Coupon
    expose :invitee, using: ::BeansApp::API::Entities::Member
  end
end
