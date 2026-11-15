# frozen_string_literal: true

FactoryBot.define do
  factory :sku_property, class: "MagicBean::SkuProperty" do
    sequence :text_zh_cn do |n|
      "text_zh_cn#{n}"
    end
    sequence :text_zh_tw do |n|
      "text_zh_tw#{n}"
    end
    sequence :text_en do |n|
      "text_en#{n}"
    end

    transient do
      sku_values_count { 5 }
    end

    before(:create) do |sku_property, evaluator|
      sku_property.sku_values_attributes = attributes_for_list(:sku_value, evaluator.sku_values_count, sku_property: sku_property)
    end
  end
end
