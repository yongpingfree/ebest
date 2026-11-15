# frozen_string_literal: true

class SyncAeOrderStatusJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = MagicBean::Order.find order_id
    return unless order.ae_drop_shipper

    status_list = []

    order.ae_order_list.each do |ae_order_no|
      retry_times = 2
      begin
        # 状态列表: https://openservice.aliexpress.com/doc/doc.htm?spm=a2o9m.11193494.0.0.4c7d6095xq679J&nodeId=27493&docId=118729#/?docId=1595
        response = Aliexpress::Api.order_detail(ae_order_no)
        error_response = response&.body.dig("error_response")

        # API limit时要重试
        if error_response.present?
          raise error_response.dig("sub_msg") || error_response.dig("msg")
        else
          result = response.body["result"]
          # 将订单信息存到数据库
          ae_order = MagicBean::AeDropShipperOrder.find_or_initialize_by(ae_order_no: ae_order_no, order_id: order.id)
          ae_order.assign_attributes(
            order_paidtime: result["order_paidtime_string"]&.in_time_zone,
            gmt_create: result["gmt_create"],
            order_status: result["order_status"],
            logistics_status: result["logistics_status"],
            order_amount: result["order_amount"].dig("amount"),
            child_order_list: result["child_order_list"],
            store_info: result["store_info"],
          )
          ae_order.save!

          status_list << result["order_status"]
        end
      rescue => e
        retry_times -= 1
        if retry_times.positive?
          retry
        else
          raise e
        end
      end
    end

    # 只有待发货和已发货需要继续查询订单状态, 来更新订单状态
    return unless order.wait_seller_send_goods? || order.wait_buyer_confirm_goods?

    if order.wait_seller_send_goods?
      # 如果子订单有一个发货，则更新为待发货
      if (status_list & ["WAIT_BUYER_ACCEPT_GOODS", "SELLER_PART_SEND_GOODS", "FINISH"]).present?
        order.deliver!
      end
    else
      # 全部子订单状态都为FINISH，则更新为已确认收货
      # TODO: 等Denis订单收货后查看订单真实数据
      if status_list.all? { |status| status == "FINISH" }
        order.receive!
        return true
      end
    end

    # 1小时后继续查询状态
    SyncAeOrderStatusJob.set(wait: MagicBean::Order::AE_SYNC_ORDER_STATUS_INTERVAL).perform_later(order_id)
  end
end 