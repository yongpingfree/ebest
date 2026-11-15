# frozen_string_literal: true

# 给商品详情页用，不返回sku property_text
module BeansApp::API::Entities
  class SkuWithoutPropertyText < MinimalStockKeepingUnit
    expose :custom_sku_groupon, as: :current_sku_groupon, using: BeansApp::API::Entities::SkuGroupon
    expose :current_time_limited_promotion_price, using: BeansApp::API::Entities::TimeLimitedPromotionPrice
    
    def custom_sku_groupon
      object.current_sku_groupon(options[:item])
    end
  end
end
