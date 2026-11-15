# frozen_string_literal: true

module BeansAdmin::API::Entities
  class Page < ::CommonEntities::Model
    expose :name
    expose :kind
    expose :content
    expose :cover
    expose :desc
    expose :position
  end
end
