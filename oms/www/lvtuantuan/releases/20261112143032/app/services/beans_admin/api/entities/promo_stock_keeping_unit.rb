# frozen_string_literal: true

module BeansAdmin::API::Entities
  class PromoStockKeepingUnit < ::CommonEntities::Model
    expose :quantity
    expose :price_in_cent
    expose :stock_keeping_unit_id

    expose :stock_keeping_unit, with: SimpleStockKeepingUnit
  end
end
