# frozen_string_literal: true

class CouponExpireNotificationJob < ApplicationJob
  queue_as :push_notification

  include ::MagicBean::Order::Messages

  # 每天凌晨1点执行
  def perform
    current_time = "06:00".in_time_zone
    start_time = current_time + 2.days + 1.second
    end_time = current_time + 3.days

    user_coupons = {}

    MagicBean::Coupon.includes(:user, coupon_template: :translations).where.not(user_id: nil).pending.where(expired_at: start_time..end_time).find_each do |coupon|
      # staging存在user_id存在，但user不存在的情况
      next unless coupon.user

      user_coupons["#{coupon.user_id}"] ||= []

      Globalize.with_locale(coupon.user.locale || "zh-CN") do
        user_coupons["#{coupon.user_id}"] << { id: coupon.id, title: coupon.coupon_template_title }
      end
    end

    user_coupons.each do |key, value|
      user = MagicBean::User.find(key)
      titles = value.uniq.map { |v| v[:title] }
      if user.locale == "en"
        coupon_titles = "#{titles.first(3).join(", ")}#{titles.length > 3 ? " and #{titles.length - 3} more" : ""}"
      else
        coupon_titles = "#{titles.first(3).join("、")}#{titles.length > 3 ? " 等" : ""}"
      end
      create_coupon_expire_app_text_message(user, coupon_titles)
    end
  end
end
