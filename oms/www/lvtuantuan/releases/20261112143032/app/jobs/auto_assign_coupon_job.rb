# frozen_string_literal: true

class AutoAssignCouponJob < ApplicationJob
  queue_as :auto_assign_coupon

  def perform(coupon_auto_assignment_id, user_id)
    coupon_auto_assignment = MagicBean::CouponAutoAssignment.find_by(id: coupon_auto_assignment_id)

    return unless coupon_auto_assignment

    user = MagicBean::User.find_by(id: user_id)

    return unless user

    coupon_auto_assignment.assign_coupons_to_user!(user)
  end
end
