# frozen_string_literal: true
module BeansAdmin::API::Entities
  class TimeLimitedPromotion < SimpleTimeLimitedPromotion
    expose :sort_time_limited_promotion_prices, as: :time_limited_promotion_prices, using: TimeLimitedPromotionPrice
  end
end
