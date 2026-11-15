# frozen_string_literal: true

module BeansAdmin::API::Entities
  class ExternalLink < ::CommonEntities::Model
    expose :name
    expose :link
  end
end
