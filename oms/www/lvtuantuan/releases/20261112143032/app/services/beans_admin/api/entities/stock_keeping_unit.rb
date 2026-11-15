# frozen_string_literal: true

module BeansAdmin::API::Entities
  class StockKeepingUnit < SimpleStockKeepingUnit
    expose :item, using: BeansAdmin::API::Entities::SimpleItem
  end
end
