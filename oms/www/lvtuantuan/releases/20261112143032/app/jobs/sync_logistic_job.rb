# frozen_string_literal: true

class SyncLogisticJob < ApplicationJob
  queue_as :logistic

  def perform(ids = nil)
    # 跳过AE订单物流同步
    # 只获取邮寄的物流
    logistics = MagicBean::Logistic.undelivered.joins(:order).where(ae_order_no: nil).where.not(no: nil).where("orders.delivery_type = ?", 2)
    logistics = logistics.where(id: ids) if ids
    Ewe::Eparcel.tracking(logistics.pluck(:no))
  end
end
