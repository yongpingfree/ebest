# frozen_string_literal: true

module BeansApp::API::Entities::Auction
  class ActivityParticipation < ::CommonEntities::Model
    expose :store_name
    expose :state, documentation: { desc: "中标状态" }
    expose :amount_in_yuan, documentation: { desc: "你的出价" }
    expose :auction_activity, using: SimpleActivity
    expose :auction_order, using: ::BeansApp::API::Entities::SimpleOrder
  end
end
