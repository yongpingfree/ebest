# frozen_string_literal: true

class ShoplineRefundNotifyJob < ApplicationJob
  queue_as :shopline

  def perform(order_id, refund_line_items)
    order = MagicBean::ThirdPartyOrder.find(order_id)

    order.refresh_shopline_order

    # TODO: 现在只要创建退款就会触发回调，先不处理库存，避免多次回调导致库存出错
    # 回退库存
    # MagicBean::StockKeepingUnit.transaction do
    #   refund_line_items.each do |item|
    #     sku = MagicBean::StockKeepingUnit.find_by(no: item[:sku])
    #     sku&.increase_inventory!(item[:quantity])
    #   end
    # end
  end
end
