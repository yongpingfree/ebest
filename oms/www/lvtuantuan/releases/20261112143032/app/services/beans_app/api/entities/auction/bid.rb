# frozen_string_literal: true

module BeansApp::API::Entities::Auction
  class Bid < Grape::Entity
    expose :id
    expose :created_at, documentation: { desc: "出价时间" }
    expose :member_id, documentation: { type: String, desc: "会员ID" }
    expose :amount_in_yuan, documentation: { desc: "出价金额" }
    expose :kind, documentation: { type: String, desc: "出价类型：direct: 直接出价、automatic: 自动出价" }
    expose :user_fuzzy_name, documentation: { type: String, desc: "用户模糊昵称" }
  end
end
