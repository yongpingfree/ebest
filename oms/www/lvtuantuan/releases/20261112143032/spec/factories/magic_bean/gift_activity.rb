# frozen_string_literal: true

FactoryBot.define do
  factory :gift_activity, class: "MagicBean::GiftActivity" do
    store { MagicBean::Store.first || association(:store) }
    start_at { Time.current.yesterday }
    end_at { Time.current.tomorrow }
    status { "enabled" }
    rules do |r|
      stock_keeping_unit = create(:stock_keeping_unit)
      [{
        "price_gradient" => 0.01,
        "all_give" => true,
        "skus" => [{
          "sku_id" => stock_keeping_unit.id,
          "quantity" => 1
        }]
      }]
    end
  end
end
