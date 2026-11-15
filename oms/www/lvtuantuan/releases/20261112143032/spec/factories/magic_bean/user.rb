# frozen_string_literal: true

FactoryBot.define do
  factory :user, class: "MagicBean::User" do

    nickname { "Jayce" }
    avatar  { "http://temp.im/200x200" }
    mobile { nil }
    gender { "male" }
    valid_orders_count { 26 }
    items_viewed_count { 262 }
    new_user { false }
    official_open_id { nil }
    subscribe { nil }
    app_open_id { nil }
    deleted_mini_open_id { nil }
    is_blocked { false }

    sequence :ebest_platform_unionid do |n|
      "obwpo0hVL0uLBcJQ_OYzrYzvWvfsx#{n}"
    end

    sequence :unionid do |n|
      "obwpo0hVL0uLBcJQ_OYzrYzvWvfsx#{n}"
    end

    sequence :session_key do |n|
      "onCuywLYgLcGmwJHCSGL9vAydiZkx#{n}"
    end

    sequence :open_id do |n|
      "oPWxX4_0o55Rd_IS6KFhi5n3jUMMx#{n}"
    end
  end
end
