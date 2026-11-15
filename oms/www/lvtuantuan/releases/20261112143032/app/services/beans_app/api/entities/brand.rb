# frozen_string_literal: true

module BeansApp::API::Entities
  class Brand < ::CommonEntities::Model
    expose :name, documentation: { type: String, desc: "品牌名称" }
    expose :cover, documentation: { type: String, desc: "品牌封面图" }
    unexpose :store_id
  end
end
