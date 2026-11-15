# frozen_string_literal: true

module BeansAdmin::API::Entities
  class MinimalFormItem < ::CommonEntities::Model
    translate_expose :title, documentation: { type: String, desc: "标题" }
  end
end
