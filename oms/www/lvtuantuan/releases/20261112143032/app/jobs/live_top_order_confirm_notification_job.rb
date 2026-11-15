# frozen_string_literal: true

class LiveTopOrderConfirmNotificationJob < ApplicationJob
  queue_as :orders

  def perform(id)
    order = MagicBean::Order.find_by(id: id)
    return if order.nil? || !order.live_top || !order.live_top_confirm? || order.express?

    Time.zone = order.order_store_time_zone

    # 如果直播订单有主单，就无需发推送
    return if order.live_top_order_has_main_orders?

    order.send_live_top_order_confirm_message

    Time.zone = ApplicationRecord::TIME_ZONE
  end
end
