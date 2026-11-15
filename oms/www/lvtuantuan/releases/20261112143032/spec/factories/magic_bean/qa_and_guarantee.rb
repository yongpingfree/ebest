# frozen_string_literal: true

FactoryBot.define do
  factory :qa_and_guarantee, class: "MagicBean::QaAndGuarantee" do
    title { "title" }
    image_zh_cn { "http://temp.im/100x100" }
    web_image { "http://temp.im/100x100" }
  end
end
