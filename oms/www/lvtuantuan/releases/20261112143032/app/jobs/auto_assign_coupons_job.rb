# frozen_string_literal: true

class AutoAssignCouponsJob < ApplicationJob
  queue_as :auto_assign_coupon

  def perform(coupon_auto_assignment_id)
    coupon_auto_assignment = MagicBean::CouponAutoAssignment.find_by(id: coupon_auto_assignment_id)

    return unless coupon_auto_assignment

    MagicBean::CouponAutoAssignment.transaction do
      if coupon_auto_assignment.everyone?
        count = 0
        MagicBean::User.all.order(:id).each_slice(500) do |slice_users|
          user_ids = slice_users.map(&:id)
          # 每分钟执行一个job, 设置时间太长的话，所有用户会跑太长时间
          BatchAutoAssignCouponJob.set(wait: count.minutes).perform_later(coupon_auto_assignment_id, user_ids)
          count += 1
        end
      else
        coupon_auto_assignment.assign_user_ids.each do |user_id|
          AutoAssignCouponJob.perform_later(coupon_auto_assignment_id, user_id)
        end
      end

      AutoAssignCouponsJob.set(wait_until: Date.tomorrow.beginning_of_day + 1.hour).perform_later(coupon_auto_assignment_id) if Date.current < coupon_auto_assignment.end_date

      coupon_auto_assignment.update(last_assigned_at: Time.current)
    end
  end
end
