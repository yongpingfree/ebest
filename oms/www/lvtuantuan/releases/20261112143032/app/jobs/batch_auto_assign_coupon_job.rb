# frozen_string_literal: true

class BatchAutoAssignCouponJob < ApplicationJob
  queue_as :auto_assign_coupon

  def perform(coupon_auto_assignment_id, user_ids)
    coupon_auto_assignment = MagicBean::CouponAutoAssignment.find_by(id: coupon_auto_assignment_id)

    return if coupon_auto_assignment.blank? || user_ids.blank?

    coupon_auto_assignment.batch_assign_coupons_to_users!(user_ids)
  end
end
