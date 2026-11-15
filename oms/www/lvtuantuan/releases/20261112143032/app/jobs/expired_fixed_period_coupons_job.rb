# frozen_string_literal: true

class ExpiredFixedPeriodCouponsJob < ApplicationJob
  queue_as :coupons

  def perform(template_id)
    coupon_template = MagicBean::CouponTemplate.find_by(id: template_id)
    if coupon_template.fixed_period? && Time.current >= coupon_template.end_at
      coupon_template.coupons.each do |coupon|
        next unless coupon.pending?
        coupon.expired!
        coupon.delete_from_redis unless coupon.received?
      end
    end
  end
end
