# frozen_string_literal: true

module BeansAdmin::API::Entities
  class QaAndGuarantee < ::CommonEntities::Model
    translate_expose :image, documentation: { desc: "说明图片" }
    translate_expose :title, documentation: { desc: "标题" }
    expose :web_image
  end
end
