# frozen_string_literal: true

class ExpiredCouponJob < ApplicationJob
  queue_as :coupons

  def perform(id)
    coupon = MagicBean::Coupon.find_by(id: id)
    if coupon && coupon.pending? && Time.current >= coupon.expired_at
      coupon.expired!
      coupon.delete_from_redis unless coupon.received?
    end
  end
end
