# frozen_string_literal: true

module BeansAdmin::API::Entities
  class ItemOnlyWithSku < ::CommonEntities::Model
    expose :stock_keeping_units, using: BeansAdmin::API::Entities::SimpleStockKeepingUnit
    expose :sku_options
  end
end
