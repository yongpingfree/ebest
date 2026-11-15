# frozen_string_literal: true

FactoryBot.define do
  factory :sku_value, class: "MagicBean::SkuValue" do
    sequence :text_zh_cn do |n|
      "text_zh_cn#{n}"
    end
    sequence :text_zh_tw do |n|
      "text_zh_tw#{n}"
    end
    sequence :text_en do |n|
      "text_en#{n}"
    end

    sku_property
  end
end
