# frozen_string_literal: true

module BeansApp::API::Entities
  class NewArrival < ::CommonEntities::Model
    expose :title, documentation: { desc: "种草标题" }
    expose :description, documentation: { desc: "种草描述" }
    expose :cover_image, documentation: { desc: "封面图" }
    expose :item_id, documentation: { type: Integer, desc: "种草商品 ID" }
  end
end
