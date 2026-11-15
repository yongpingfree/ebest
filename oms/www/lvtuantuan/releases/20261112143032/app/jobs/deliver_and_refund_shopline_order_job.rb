# frozen_string_literal: true

class DeliverAndRefundShoplineOrderJob < ApplicationJob
  queue_as :shopline

  def perform(id, full_refund = false, stockout_items = [], logistic_no = nil)
    order = MagicBean::ThirdPartyOrder.find(id)

    order.shopline_deliver_and_refund(logistic_no: logistic_no, stockout_items: stockout_items, full_refund: full_refund)
  end
end
