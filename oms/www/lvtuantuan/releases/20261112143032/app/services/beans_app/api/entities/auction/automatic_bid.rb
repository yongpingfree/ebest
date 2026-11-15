# frozen_string_literal: true

module BeansApp::API::Entities::Auction
  class AutomaticBid < Grape::Entity
    expose :id
    expose :created_at, documentation: { desc: "出价时间" }
    expose :amount_limit_in_yuan, documentation: { desc: "出价上限" }
  end
end
