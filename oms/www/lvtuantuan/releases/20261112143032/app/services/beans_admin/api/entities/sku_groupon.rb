# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SkuGroupon < ::CommonEntities::Model
    expose :enabled
    expose :price_in_yuan
    expose :stock_keeping_unit, using: BeansAdmin::API::Entities::StockKeepingUnit
  end
end
