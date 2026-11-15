# frozen_string_literal: true

module BeansAdmin::API::Entities
  class GiftCardSimpleOrder < ::CommonEntities::Model
    expose :no
    expose :type
    expose :amount_in_cent
    expose :payment_in_cent
    expose :actually_amount_in_cent
    expose :amount_in_yuan
    expose :payment_in_yuan
    expose :total_payment_in_yuan
    expose :actually_amount_in_yuan
    expose :gift_card_amount_in_cent
    expose :gift_card_amount_in_yuan
    expose :freight_in_yuan
    expose :freight_in_cent
    expose :status
  end
end
