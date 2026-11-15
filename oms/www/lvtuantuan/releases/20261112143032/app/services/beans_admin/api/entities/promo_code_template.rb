# frozen_string_literal: true

module BeansAdmin::API::Entities
  class PromoCodeTemplate < SimplePromoCodeTemplate
    expose :promo_stock_keeping_units, with: PromoStockKeepingUnit
  end
end
