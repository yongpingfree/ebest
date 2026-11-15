# frozen_string_literal: true

FactoryBot.define do
  factory :category, class: "MagicBean::Category" do
    sequence :name_zh_cn do |n|
      "name cn #{n}"
    end
    sequence :name_zh_tw do |n|
      "name tw #{n}"
    end
    sequence :name_en do |n|
      "name en #{n}"
    end
    status { "show" }

    trait :as_child do
      parent { create(:category) }
    end
  end
end
