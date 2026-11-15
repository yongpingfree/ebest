# frozen_string_literal: true

class PromotionPriceResetItemPriceJob < ApplicationJob
  queue_as :default

  def perform(promotion_price_id)
    promotion_price = MagicBean::TimeLimitedPromotionPrice.find_by(id: promotion_price_id)
    promotion_price.send :update_item_price if promotion_price
  end
end
