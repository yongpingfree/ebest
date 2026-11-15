# frozen_string_literal: true

FactoryBot.define do
  factory :live_room, class: "MagicBean::LiveRoom" do
    title { "Live" }
    start_at { Time.current }
    app_push_protocol { :rtmp }
    app_pull_protocol { :flv }
    subscription_noti_title { "Subscription Title" }
    subscription_noti_body { "Subscription Body" }
    host_nickname { "eBest" }
    association :host, factory: :user
    association :admin_user, factory: :admin_user
    association :store, factory: :store
  end
end
