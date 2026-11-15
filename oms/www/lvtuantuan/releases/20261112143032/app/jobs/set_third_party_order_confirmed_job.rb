# frozen_string_literal: true

class SetThirdPartyOrderConfirmedJob < ApplicationJob
  queue_as :orders

  # 有可能截单时间是 23:59, 但执行时间是第二天00:16，所以把cutoff_date也传过来
  def perform(id, cutoff_date_str = nil)
    order = MagicBean::ThirdPartyOrder.find_by(id: id)
    return if order.nil?

    Time.zone = order.order_store_time_zone

    # 判断日期，避免修改订单日期的订单提前确认
    return if order.delivery_date.to_date.yesterday != (cutoff_date_str&.to_date || Date.current)

    if order.pending?
      order.confirmed!
      # shopline退款只选金额，refund收不到回调，支付状态仍是paid，在确认订单的时候更新订单，避免生产仓储订单
      order.refresh_shopline_order
    end

    Time.zone = ApplicationRecord::TIME_ZONE
  end
end
