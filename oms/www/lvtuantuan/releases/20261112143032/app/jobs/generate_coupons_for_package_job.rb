# frozen_string_literal: true

class GenerateCouponsForPackageJob < ApplicationJob
  queue_as :coupons

  def perform(package_id, user_id)

    package = MagicBean::CouponPackage.find_by(id: package_id)
    user = MagicBean::User.find_by(id: user_id)
    if package && user
      package.coupon_templates.each do |template|
        template.generate_coupons_and_assign_to_users([user.id])
      end
    end
  end
end
