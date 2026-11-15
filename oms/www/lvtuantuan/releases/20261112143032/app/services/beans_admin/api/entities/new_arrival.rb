# frozen_string_literal: true

module BeansAdmin::API::Entities
  class NewArrival < ::CommonEntities::Model
    expose :title, documentation: { desc: "种草标题" }
    expose :description, documentation: { desc: "种草描述" }
    expose :position, documentation: { type: Integer, desc: "位置排序，数字越小排序越前" }
    expose :hidden, documentation: { type: Grape::API::Boolean, desc: "是否显示" }
    expose :cover_image, documentation: { desc: "封面图" }
    expose :item_id, documentation: { type: Integer, desc: "种草商品 ID" }
    expose :item_title, documentation: { type: String, desc: "种草商品标题" }
  end
end
