# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SkuProperty < ::CommonEntities::Model
    expose :text, documentation: { type: String, desc: "规格名" }
  end
end
