# frozen_string_literal: true

FactoryBot.define do
  factory :brand, class: "MagicBean::Brand" do
    sequence :name_zh_cn do |n|
      "name cn #{n}"
    end
    sequence :name_zh_tw do |n|
      "name tw #{n}"
    end
    sequence :name_en do |n|
      "name en #{n}"
    end
  end
end
