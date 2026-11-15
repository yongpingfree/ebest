# frozen_string_literal: true

class SetOrderConfirmedJob < ApplicationJob
  queue_as :orders

  # 有可能截单时间是 23:59, 但执行时间是第二天00:16，所以把cutoff_date也传过来
  def perform(id, same_day_delivery = false, cutoff_date_str = nil)
    order = MagicBean::Order.find_by(id: id)
    return if order.nil?

    Time.zone = order.order_store_time_zone

    # 拼团成功后往往已经过了配送日期，所以拼团订单不需要判断日期
    if order.type != "MagicBean::GrouponOrder" && !order.express?
      if same_day_delivery
        return if order.delivery_date.to_date != (cutoff_date_str&.to_date || Date.current)
      else
        return if order.delivery_date.to_date.yesterday != (cutoff_date_str&.to_date || Date.current)
      end
    end

    if order.live_top_confirm?
      order.confirm_live_top_order
    elsif order.pending?
      # 确认场景
      # 1. 订单为母单
      # 2. 订单为加单子单，且存在母单
      order.confirmed! if !order.is_child || (order.is_child && order.has_other_parent_orders?)      
    end

    Time.zone = ApplicationRecord::TIME_ZONE
  end
end
