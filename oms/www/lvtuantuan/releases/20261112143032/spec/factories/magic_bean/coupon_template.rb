# frozen_string_literal: true

FactoryBot.define do
  factory :coupon_template, class: "MagicBean::CouponTemplate" do
    title_zh_cn { "优惠券" }
    title_zh_tw { "优惠券" }
    title_en { "Coupon Template" }
    kind { "reduction" }
    time_kind { "first_day" }
    time_limit_in_day { 0 }
    enabled { true }
    details_image { "http://temp.im/100x100" }
    user_kind { "all_user" }
    target_kind { "item" }
    channel { "general" }

    store { MagicBean::Store.first || association(:store) }

    trait :with_500_denominations do
      denominations_in_cent { 500 }
    end

    trait :with_1500_denominations do
      denominations_in_cent { 1500 }
    end

    trait :with_category_ids do
      category_ids { [1, 2] }
    end
  end
end
