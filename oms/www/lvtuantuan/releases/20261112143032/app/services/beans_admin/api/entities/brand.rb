# frozen_string_literal: true

module BeansAdmin::API::Entities
  class Brand < ::CommonEntities::Model
    translate_expose :name
    expose :cover, documentation: { type: String, desc: "品牌封面图" }
    expose :position, documentation: { desc: "排序，数字越小排序越前" }
  end
end
