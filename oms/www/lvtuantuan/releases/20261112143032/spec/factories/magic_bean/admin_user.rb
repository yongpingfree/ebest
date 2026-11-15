# frozen_string_literal: true

FactoryBot.define do
  factory :admin_user, class: "MagicBean::AdminUser" do
    name { "Admin" }
    mobile { "13800138000" }
    email { "admin@example.com" }
    role { :super_admin }
    state { :active }
    password { "eBest#1234" }
    password_confirmation { "eBest#1234" }
  end
end
