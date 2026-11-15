# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SkuValue < ::CommonEntities::Model
    expose :sku_property_id
    expose :text, documentation: { type: String, desc: "规格值" }
    expose :ae_property_value_id
  end
end
