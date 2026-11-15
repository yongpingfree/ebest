# frozen_string_literal: true

module BeansAdmin::API::Entities
  class TopLeftItemTagDetail < TopLeftItemTag
    expose :items, using: BeansAdmin::API::Entities::MinimalItem
  end
end
