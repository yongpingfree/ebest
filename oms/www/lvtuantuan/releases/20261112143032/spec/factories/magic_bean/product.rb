# frozen_string_literal: true

FactoryBot.define do
  factory :product, class: "MagicBean::Product" do
    title { "title" }
    description { "description" }
    shared_description { "shared_description" }
    detail_images { ["http://temp.im/100x100"] }
    main_images { ["http://temp.im/100x100"] }
    cover { "http://temp.im/100x100" }

    category
    brand
    store { MagicBean::Store.first || association(:store) }
    qa_and_guarantee
  end
end
