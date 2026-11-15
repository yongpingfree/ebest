# frozen_string_literal: true

module BeansAdmin::API::Entities
  class CategoryDetail < Category
    expose :sort_items, using: ::BeansAdmin::API::Entities::MinimalItem
  end
end
