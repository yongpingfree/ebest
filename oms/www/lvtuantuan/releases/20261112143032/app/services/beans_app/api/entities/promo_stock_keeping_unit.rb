# frozen_string_literal: true

module BeansApp::API::Entities
  class PromoStockKeepingUnit < ::CommonEntities::Model
    expose :stock_keeping_unit, with: SimpleStockKeepingUnit
    expose :price_in_cent
    expose :price_in_yuan
    expose :quantity
  end
end
