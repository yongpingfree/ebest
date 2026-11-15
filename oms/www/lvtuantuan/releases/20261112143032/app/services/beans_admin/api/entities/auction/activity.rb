# frozen_string_literal: true

module BeansAdmin::API::Entities::Auction
  class Activity < SimpleActivity
    translate_expose :description, documentation: { type: String, desc: "描述" }
    expose :main_images, documentation: { desc: "主图" }
    expose :detail_images, documentation: { desc: "详情图" }
    expose :brand_id, documentation: { desc: "品牌ID" }
    expose :qa_and_guarantee_id
    expose :qa_and_guarantee, using: BeansAdmin::API::Entities::QaAndGuarantee
  end
end
