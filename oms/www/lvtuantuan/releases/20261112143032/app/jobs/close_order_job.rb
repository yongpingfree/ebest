# frozen_string_literal: true

class CloseOrderJob < ApplicationJob
  queue_as :orders

  def perform(id)
    order = MagicBean::Order.find_by(id: id)
    if order && order.wait_buyer_pay?
      if order.omipay_transaction_id.present?
        order.no_callback_omipay_order_rehandle
      elsif order.supay_platform?
        order.no_callback_supay_order_rehandle
      elsif order.stripe_transaction_id?
        order.no_callback_stripe_order_rehandle
      else
        order.close!
      end
    end
  end
end
