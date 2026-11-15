# frozen_string_literal: true

class RefundOrderJob < ApplicationJob
  queue_as :orders

  def perform(order_id)
    order = MagicBean::Order.find(order_id)
    if order.refundable?
      order.refund!
    else
      raise "订单#{order.no}不可退款"
    end
  end
end
