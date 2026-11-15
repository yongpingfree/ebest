# frozen_string_literal: true

FactoryBot.define do
  factory :stock_keeping_unit, class: "MagicBean::StockKeepingUnit" do
    cost_price_in_cent { 0 }
    image { "https://cdn.minimall.donkibuy.com/items/test_sku.jpg" }
    on_sale { true }
    quantity { 100 }
    price_in_cent { 1000 }
    strikethrough_price_in_cent { 1100 }

    sequence :properties do |n|
      property = MagicBean::SkuProperty.last
      sku_value = property.sku_values.to_a[(n-1)%5]
      "#{property.id}:#{sku_value.id}"
    end
    sequence :no do |n|
      "no#{n}"
    end
    sequence :barcode do |n|
      "barcode#{n}"
    end
    item
  end
end
