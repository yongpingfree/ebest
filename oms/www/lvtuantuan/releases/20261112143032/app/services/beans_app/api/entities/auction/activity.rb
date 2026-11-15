# frozen_string_literal: true

module BeansApp::API::Entities::Auction
  class Activity < SimpleActivity
    expose :main_images, documentation: { desc: "主图" }
    expose :detail_images, documentation: { desc: "详情图" }
    expose :best_bid, using: Bid
    expose :qa_and_guarantee_image, documentation: { desc: "答疑和保障图片URL" }
    expose :best_bid_user_fuzzy_name, documentation: { desc: "最高出价者昵称" }
  end
end
