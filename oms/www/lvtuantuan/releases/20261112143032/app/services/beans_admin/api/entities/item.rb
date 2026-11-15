# frozen_string_literal: true

module BeansAdmin::API::Entities
  class Item < ItemWithoutSku
    expose :stock_keeping_units, using: BeansAdmin::API::Entities::SkuWithNotSyncedQuantity
    expose :sku_options
    expose :product, as: :product_attributes, using: BeansAdmin::API::Entities::Product
    expose :product_id
  end
end
