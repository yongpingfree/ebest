# frozen_string_literal: true

module BeansAdmin::API::Entities
  class Category < SimpleCategory
    expose :children, using: BeansAdmin::API::Entities::ChildCategory, documentation: { type: BeansAdmin::API::Entities::ChildCategory, is_array: true }
  end
end
