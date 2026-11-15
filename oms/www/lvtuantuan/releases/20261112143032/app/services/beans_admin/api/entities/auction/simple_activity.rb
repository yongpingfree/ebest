# frozen_string_literal: true

module BeansAdmin::API::Entities::Auction
  class SimpleActivity < ::CommonEntities::Model
    translate_expose :title
    expose :cover
    expose :auto_renewal_end_at
    expose :state
    expose :final_end_at
    expose :start_at
    expose :default_end_at
    expose :starting_price_in_yuan
    expose :bidding_increments_in_yuan
    expose :reserve_price_in_yuan
    expose :directly_purchase_price_in_yuan
    expose :category_id
    expose :category_name
    expose :minor_category_id
    expose :minor_category_name
    expose :brand_name, documentation: { desc: "品牌" }
    expose :bids_count, documentation: { desc: "出价次数" }
    expose :best_bid_amount_in_yuan, documentation: { desc: "目前出价" }
    expose :can_edit?, as: :can_edit
  end
end
