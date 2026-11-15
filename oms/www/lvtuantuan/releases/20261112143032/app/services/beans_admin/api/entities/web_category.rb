# frozen_string_literal: true

module BeansAdmin::API::Entities
  class WebCategory < SimpleWebCategory
    expose :children, using: BeansAdmin::API::Entities::ChildWebCategory, documentation: { type: BeansAdmin::API::Entities::ChildWebCategory, is_array: true }
  end
end
