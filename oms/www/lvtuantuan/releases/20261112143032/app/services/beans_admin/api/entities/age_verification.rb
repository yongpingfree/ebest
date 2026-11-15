# frozen_string_literal: true

module BeansAdmin::API::Entities
  class AgeVerification < ::CommonEntities::Model
    translate_expose :title
    translate_expose :content
    expose :image
    expose :parent_category_id
    expose :parent_category_name
    expose :parent_web_category_id
    expose :parent_web_category_name
  end
end
