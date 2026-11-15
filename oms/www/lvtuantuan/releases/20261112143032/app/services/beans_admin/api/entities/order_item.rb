# frozen_string_literal: true

module BeansAdmin::API::Entities
  class OrderItem < SimpleOrderItem
    expose :can_refund_quantity do |object|
      object.quantity - object.refund_quantity
    end
  end
end
