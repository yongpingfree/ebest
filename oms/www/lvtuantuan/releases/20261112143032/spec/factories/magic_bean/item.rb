# frozen_string_literal: true

FactoryBot.define do
  factory :item, class: "MagicBean::Item" do
    no { SecureRandom.hex(4) }
    title_zh_cn { "title cn" }
    title_zh_tw { "title tw" }
    title_en { "title en" }
    sub_title { "sub_title" }
    description_zh_cn { "description" }
    description_zh_tw { "description" }
    description_en { "description" }
    shared_description_zh_cn { "shared_description" }
    shared_description_zh_tw { "shared_description" }
    shared_description_en { "shared_description" }
    detail_images { ["https://cdn.minimall.donkibuy.com/items/test_detail.jpg"] }
    main_images { ["https://cdn.minimall.donkibuy.com/items/test_main.jpg"] }
    cover { "https://cdn.minimall.donkibuy.com/items/test_cover.jpg" }
    listing_type { "online" }
    freight_type { "freight_fixed" }
    delivery_type { ["merchant_delivery", "self_pick"] }
    channels { MagicBean::Item::CHANNEL_ARRAY }
    fixed_freight_cost { 100 }
    fixed_freight { 200 }
    buy_quota { 0 }
    buy_quota_days { 0 }

    qa_and_guarantee
    category { association(:category, :as_child) }
    brand
    store { MagicBean::Store.first || association(:store) }
    product

    transient do
      stock_keeping_units_count { 5 }
    end

    before(:create) do |item, evaluator|
      sku_property = create(:sku_property)
      item.stock_keeping_units_attributes = attributes_for_list(:stock_keeping_unit, evaluator.stock_keeping_units_count, item: item)
    end
  end
end
