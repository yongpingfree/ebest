# frozen_string_literal: true
module BeansAdmin::API::Entities
  class SimpleWebCustomList < ::CommonEntities::Model
    translate_expose :title, documentation: { type: String, desc: "标题" }
    expose :position, documentation: { type: Integer, desc: "权重" }
    expose :page_location, documentation: { type: String, desc: "所在页面位置" }
    expose :orientation, documentation: { type: String, desc: "展示方向" }
    expose :displayed, documentation: { type: Grape::API::Boolean }
    expose :items_shuffled, documentation: { type: Grape::API::Boolean }
    expose :store_name
  end
end
