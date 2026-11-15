# frozen_string_literal: true

class ExpiredGiftCardCouponJob < ApplicationJob
  queue_as :coupons

  def perform(id)
    template = MagicBean::GiftCardTemplate.find_by(id: id)
    template.gift_card_coupons.pending.update_all(status: :expired) if template
  end
end
