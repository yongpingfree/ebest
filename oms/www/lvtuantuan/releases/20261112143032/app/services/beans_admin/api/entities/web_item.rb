# frozen_string_literal: true

module BeansAdmin::API::Entities
  class WebItem < ::CommonEntities::Model
    expose :upper_images, documentation: { type: Array[String], desc: "上部图片组" }
    expose :lower_images, documentation: { type: Array[String], desc: "下部图片组" }
    expose :banner_images, documentation: { type: Array[String], desc: "产品banner" }
    expose :video, documentation: { type: String, desc: "视频" }
  end
end
