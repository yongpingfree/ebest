# frozen_string_literal: true

namespace :hotfix do
  desc "为生鲜小程序用户生成优惠券模板"
  task create_coupon_template_for_fresh: :environment do
    MagicBean::CouponTemplate.transaction do
      attrs = [1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 22, 25, 30].map do |amount|
        amount_in_cent = amount * 100
        attr = {
          title: "你好鲜生余额抵用券 #{amount} 元券",
          kind: "reduction",                          # 满减，无门槛
          denominations_in_cent: amount_in_cent,      # 金额
          time_kind: "first_day",                     # 领取第一天起
          time_limit_in_day: 365,                     # 365天
          details_image: "https://cdn.minimall.donkibuy.com/images/201202/12ohqrtlt.jpeg?x-oss-process=image/resize,w_750/quality,q_100",    # 详情图
          enabled: true,
          user_kind: "all_user",
          target_kind: "item",
          channel: "general",
          code: "fresh#{amount}"
        }
        MagicBean::CouponTemplate.create!(attr)
      end
    end
  end
end
