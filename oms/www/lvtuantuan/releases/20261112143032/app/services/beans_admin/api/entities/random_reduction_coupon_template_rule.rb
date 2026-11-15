# frozen_string_literal: true

module BeansAdmin::API::Entities
  class RandomReductionCouponTemplateRule < ::CommonEntities::Model
    expose :min_amount_in_yuan
    expose :max_amount_in_yuan
    expose :max_quantity
  end
end
