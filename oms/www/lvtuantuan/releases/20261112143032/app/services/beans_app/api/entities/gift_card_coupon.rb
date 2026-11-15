# frozen_string_literal: true

module BeansApp::API::Entities
  class GiftCardCoupon < ::CommonEntities::Model
    expose :code
    expose :denominations_in_cent
    expose :denominations_in_yuan
    expose :used_amount_in_cent
    expose :used_amount_in_yuan
    expose :unused_amount_in_cent
    expose :unused_amount_in_yuan
    expose :pin_code
    expose :status
    expose :expired_at
    expose :not_eligible_for_free_gift
  end
end
