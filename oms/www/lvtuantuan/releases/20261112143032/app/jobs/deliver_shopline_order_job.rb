# frozen_string_literal: true

class DeliverShoplineOrderJob < ApplicationJob
  queue_as :shopline

  def perform(id, logistic_no, company)
    order = MagicBean::ThirdPartyOrder.find(id)

    # 先更新shopline订单
    order.refresh_shopline_order

    order.shopline_deliver(logistic_no, company)
  end
end
