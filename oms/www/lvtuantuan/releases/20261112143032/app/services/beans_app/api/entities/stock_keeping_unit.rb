# frozen_string_literal: true

module BeansApp::API::Entities
  class StockKeepingUnit < SimpleStockKeepingUnit
    expose :custom_sku_groupon, as: :current_sku_groupon, using: BeansApp::API::Entities::SkuGroupon
    expose :current_time_limited_promotion_price, using: BeansApp::API::Entities::TimeLimitedPromotionPrice
    expose :is_subscribe_sku_in_stock_notice, documentation: { desc: "是否已订阅到货通知", type: Grape::API::Boolean }

    def is_subscribe_sku_in_stock_notice
      return false unless current_user

      if options[:pending_sku_ids].nil?
        object.sku_in_stock_notices.pending.exists?(user_id: current_user.id)
      else
        options[:pending_sku_ids].include?(object.id)
      end
    end

    def custom_sku_groupon
      object.current_sku_groupon(options[:item])
    end
  end
end
