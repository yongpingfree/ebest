# frozen_string_literal: true

FactoryBot.define do
  factory :member, class: "MagicBean::Member" do

    mobile { "61400999999" }
    birthday { nil }
    available_integral { 1000 }
    blocked_integral { 0 }
    cumulative_integral { 1000 }
    assigned_app_newbie_coupon { false }

    user
  end
end
