# frozen_string_literal: true

FactoryBot.define do
  factory :groupon_activity, class: "MagicBean::GrouponActivity" do
    kind { "item" }
    price_in_cent { 500 }
    start_at { Time.current.yesterday }
    end_at { Time.current.tomorrow }
    user_count { 2 }
    enabled { true }
    is_real { true }
    expired_hours { 100 }
    type { "MagicBean::NormalGrouponActivity" }
    wms_sync_type { "after_groupon_finished" }

    item { MagicBean::Item.first || association(:item) }
    store { MagicBean::Store.first || association(:store) }
  end
end
