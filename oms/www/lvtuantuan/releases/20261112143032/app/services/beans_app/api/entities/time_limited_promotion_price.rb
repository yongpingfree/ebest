# frozen_string_literal: true

module BeansApp::API::Entities
  class TimeLimitedPromotionPrice < ::CommonEntities::Model
    expose :time_limited_promotion_id
    expose :price_in_yuan
    expose :start_at
    expose :end_at
  end
end
