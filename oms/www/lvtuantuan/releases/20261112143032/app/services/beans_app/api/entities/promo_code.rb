# frozen_string_literal: true

module BeansApp::API::Entities
  class PromoCode < ::CommonEntities::Model
    expose :promo_stock_keeping_units, with: PromoStockKeepingUnit
  end
end
