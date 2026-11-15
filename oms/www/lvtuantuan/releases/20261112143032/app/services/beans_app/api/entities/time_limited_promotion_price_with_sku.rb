# frozen_string_literal: true

module BeansApp::API::Entities
  class TimeLimitedPromotionPriceWithSku < ::CommonEntities::Model
    expose :time_limited_promotion_id
    expose :price_in_yuan
    expose :start_at
    expose :end_at
    expose :stock_keeping_unit, with: ::BeansApp::API::Entities::TimeLimitedPromotionSku
  end
end
