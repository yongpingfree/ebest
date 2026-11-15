# frozen_string_literal: true

module BeansAdmin::API::Entities
  class GiftCardCoupon < ::CommonEntities::Model
    expose :code
    expose :pin_code
    expose :denominations_in_cent
    expose :denominations_in_yuan
    expose :used_amount_in_cent
    expose :used_amount_in_yuan
    expose :status
    expose :expired_at
    expose :not_eligible_for_free_gift
    expose :effective_orders, as: :orders, using: ::BeansAdmin::API::Entities::GiftCardSimpleOrder
  end
end
