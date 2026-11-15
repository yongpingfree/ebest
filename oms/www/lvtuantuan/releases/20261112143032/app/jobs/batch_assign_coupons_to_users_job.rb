# frozen_string_literal: true

class BatchAssignCouponsToUsersJob < ApplicationJob
  queue_as :coupons

  def perform(coupon_template_id, file_url, admin_user_id)
    MagicBean::CouponTemplate.batch_assign_coupons_via_csv_file(
      coupon_template_id, file_url, admin_user_id
    )
  end
end
