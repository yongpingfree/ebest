# frozen_string_literal: true

module BeansAdmin::API::Entities
  class GrouponOrder < SimpleGrouponOrder
    expose :order_items, using: BeansAdmin::API::Entities::OrderItem, documentation: { is_array: true }
  end
end
