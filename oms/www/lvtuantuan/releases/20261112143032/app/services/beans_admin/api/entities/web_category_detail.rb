# frozen_string_literal: true

module BeansAdmin::API::Entities
  class WebCategoryDetail < WebCategory
    expose :sort_items, using: ::BeansAdmin::API::Entities::MinimalItem
  end
end
