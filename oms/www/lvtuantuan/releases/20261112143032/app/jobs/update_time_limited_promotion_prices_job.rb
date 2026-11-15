# frozen_string_literal: true

class UpdateTimeLimitedPromotionPricesJob < ApplicationJob
  queue_as :orders # 为免再增加多一个 sidekiq queue，重用优先级最高的 orders queue

  def perform(id, action)
    promotion = MagicBean::TimeLimitedPromotion.find_by(id: id)

    return if promotion.nil?

    begin
      promotion.send(action)
    rescue AASM::InvalidTransition
      # do nothing
    end
  end
end
