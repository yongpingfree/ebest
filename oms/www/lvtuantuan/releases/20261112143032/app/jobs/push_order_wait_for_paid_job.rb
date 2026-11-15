# frozen_string_literal: true

class PushOrderWaitForPaidJob < ApplicationJob
  queue_as :orders

  def perform(id)
    order = MagicBean::Order.find_by(id: id)
    if order && order.wait_buyer_pay?
      MagicBean::AppNotifier.enqueue_app_push_job("订单支付", "订单“#{order.no}”5分钟后将会关闭，请尽快完成支付", order.user_id, { app_link: { type: "order", params: { id: order.id } }.to_json })
    end
  end
end
