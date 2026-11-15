# frozen_string_literal: true
module BeansAdmin::API::Entities
  class CustomList < SimpleCustomList
    expose :no_sort_items, as: :items, using: ::BeansAdmin::API::Entities::MinimalItem
  end
end
