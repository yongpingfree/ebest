# frozen_string_literal: true

FactoryBot.define do
  factory :gift_card_template, class: "MagicBean::GiftCardTemplate" do
    denominations_in_cent { 1000 }
    quantity { 2 }
    expired_at { Time.current.tomorrow }
    purchaser { "EWE" }

    trait :with_1000_denominations do
      denominations_in_cent { 1000 }
    end

    trait :with_2500_denominations do
      denominations_in_cent { 2500 }
    end
  end
end
