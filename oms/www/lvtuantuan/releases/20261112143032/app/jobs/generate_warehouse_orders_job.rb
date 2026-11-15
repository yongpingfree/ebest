# frozen_string_literal: true

class GenerateWarehouseOrdersJob < ApplicationJob
  queue_as :orders

  def perform
    yesterday_date = Date.yesterday.strftime("%Y-%m-%d")
    ransack_params = {
      sync_status_eq: :confirmed,
      status_eq: :wait_seller_send_goods,
      delivery_date_gt: yesterday_date,
      warehouse_order_id_null: true,
      delivery_date_not_null: true # 拼团订单在成团前不会有配送日期
    }

    order_ids = []
    order_ids += MagicBean::NormalOrder.ransack(ransack_params).result.ids
    order_ids += MagicBean::SameDayDeliveryOrder.ransack(ransack_params).result.ids
    order_ids += MagicBean::GrouponOrder.ransack(ransack_params.merge({ groupon_status_in: ["finished", "free"] })).result.ids

    # 限制每天推送给快马配送的订单数量
    kuaima_order_number_set = Set.new
    kuaima_delivery_max_count = MagicBean::SiteConfig.default_config.kuaima_delivery_max_count.to_i

    MagicBean::Order.where(id: order_ids).order(id: :asc).find_each do |order|
      # 避免job重复执行导致重复创建仓储订单，已经生成仓储订单的订单直接跳过
      next if order.warehouse_order_id.present?

      # 邮寄订单不合并订单
      if order.express?
        warehouse_order_uniq_hash = order.warehouse_order_uniq_hash.merge({ deliver_to_door: order.deliver_to_door, authority_to_leave: order.authority_to_leave })
        wo = MagicBean::WarehouseOrder.create(warehouse_order_uniq_hash)
      else
        wo = MagicBean::WarehouseOrder.find_or_initialize_by(order.warehouse_order_uniq_hash)
        if wo.new_record?
          wo.deliver_to_door = order.deliver_to_door
          wo.authority_to_leave = order.authority_to_leave
        else
          # authority_to_leave 有多个值 —> 取 false
          # deliver_to_door 有多个值 —> 取 true
          wo.deliver_to_door = true if wo.deliver_to_door != order.deliver_to_door
          wo.authority_to_leave = false if wo.authority_to_leave != order.authority_to_leave
        end
        wo.save
      end
      
      wo.append(order)
      if wo.satisfy_kuaima_delivery?
        if kuaima_delivery_max_count.positive? && kuaima_order_number_set.size < kuaima_delivery_max_count
          wo.update_column :express_carrier, MagicBean::Order::KUAIMA_COMPANY
          kuaima_order_number_set.add wo.no
        end
      else
        wo.update_column :express_carrier, nil
        kuaima_order_number_set.delete wo.no
      end
    end

    shopline_ransack_params = {
      sync_status_eq: :confirmed,
      delivery_date_gt: yesterday_date,
      warehouse_order_id_null: true,
      delivery_date_not_null: true,
      financial_status_eq: "paid"
    }

    MagicBean::ThirdPartyOrder.ransack(shopline_ransack_params).result.each { |order| order.generate_shopline_warehouse_order }
  end
end
