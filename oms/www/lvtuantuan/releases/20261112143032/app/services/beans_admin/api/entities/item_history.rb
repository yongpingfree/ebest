# frozen_string_literal: true

module BeansAdmin::API::Entities
  class ItemHistory < MinimalItem
    expose :page_views_count
    expose :user_views_count
  end
end
