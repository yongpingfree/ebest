# frozen_string_literal: true

module BeansAdmin::API::Entities
  class PromoCode < SimplePromoCode
    expose :paid_orders, as: :orders, with: SimpleOrder
  end
end
