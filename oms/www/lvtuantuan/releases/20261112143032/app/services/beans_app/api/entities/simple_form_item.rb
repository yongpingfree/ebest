# frozen_string_literal: true

module BeansApp::API::Entities
  class SimpleFormItem < ::CommonEntities::Model
    translate_expose :title, documentation: { type: String, desc: "标题" }
    translate_expose :description, documentation: { type: String, desc: "描述" }
    expose :cover
  end
end
