# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleNormalOrder < Order
    expose :coupon, using: BeansAdmin::API::Entities::Coupon
  end
end
