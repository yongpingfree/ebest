# frozen_string_literal: true

FactoryBot.define do
  factory :store, class: "MagicBean::Store" do
    name { "Sydney" }
    sequence :short_name do |n|
      ("A".."BZ").to_a[n]
    end
  end
end
