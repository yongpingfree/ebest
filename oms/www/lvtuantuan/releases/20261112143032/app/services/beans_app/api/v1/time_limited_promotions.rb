# frozen_string_literal: true

module BeansApp
  class API::V1::TimeLimitedPromotions < ::API
    # 限时优惠 API
    namespace :time_limited_promotions, desc: "限时优惠 API" do
      route_param :id do
        desc "限时优惠详情", {
          success: API::Entities::TimeLimitedPromotion,
          skip_authentication: true
        }
        get do
          present resource, with: ::BeansApp::API::Entities::TimeLimitedPromotion
        end          

        desc "SKU列表", {
          success: API::Entities::TimeLimitedPromotionPriceWithSku,
          skip_authentication: true,
          is_array: true
        }
        paginate
        get "skus" do
          skus = resource.time_limited_promotion_prices.ransack(stock_keeping_unit_on_sale_eq: true, stock_keeping_unit_item_listing_type_in: ["online", "advance_on"]).result.includes(stock_keeping_unit: [item: [:on_sale_skus, :translations]]).order("case when stock_keeping_units.quantity > 0 then false else true end ASC, time_limited_promotion_prices.position ASC, time_limited_promotion_prices.id ASC")
          present paginate(skus), with: ::BeansApp::API::Entities::TimeLimitedPromotionPriceWithSku
        end
      end
    end
  end
end
