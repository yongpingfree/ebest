# frozen_string_literal: true

module BeansApp::API::Entities::Auction
  class SimpleActivity < ::CommonEntities::Model
    expose :no, documentation: { type: String, desc: "拍卖编号" }
    expose :title, documentation: { type: String, desc: "标题" }
    expose :description, documentation: { type: String, desc: "描述" }
    expose :cover, documentation: { type: String, desc: "封面图" }
    expose :has_reserve_price?, as: :has_reserve_price, documentation: { desc: "是否有底价" }
    expose :auto_renewal_end_at, documentation: { desc: "是否自动延长拍卖时间" }
    expose :state, documentation: { desc: "拍卖状态" }
    expose :start_at, documentation: { desc: "开始时间" }
    expose :final_end_at, documentation: { desc: "拍卖结束时间" }
    expose :bidding_increments_in_yuan, documentation: { desc: "出价最小增额" }
    expose :starting_price_in_yuan, documentation: { desc: "起标价" }
    expose :directly_purchase_price_in_yuan, documentation: { desc: "直接购买价" }
    expose :bids_count, documentation: { desc: "出价次数" }
    expose :stock_keeping_unit_id, documentation: { desc: "SKU ID" }
    expose :best_bid_amount_in_yuan, documentation: { desc: "目前出价" }
  end
end
