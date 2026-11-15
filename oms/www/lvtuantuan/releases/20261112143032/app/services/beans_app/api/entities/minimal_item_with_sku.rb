# frozen_string_literal: true

# 给预览加入购物车接口用
module BeansApp::API::Entities
  class MinimalItemWithSku < MinimalItem
    expose :on_sale_sku_options, as: :sku_options
    expose :on_sale_skus, as: :stock_keeping_units, using: BeansApp::API::Entities::MinimalStockKeepingUnit
    expose :price_range
    expose :min_price
    expose :max_price
    expose :current_store_can_buy
    expose :active_groupon_activity, using: BeansApp::API::Entities::GrouponActivity
    expose :advance_on?, as: :is_advance_on
    expose :start_selling_at
    expose :is_presell
    expose :presell_end_at
    expose :maximun_strikethrough_price_in_yuan, documentation: { desc: "最大划线价" }

    def current_store_can_buy
      true
    end
  end
end
