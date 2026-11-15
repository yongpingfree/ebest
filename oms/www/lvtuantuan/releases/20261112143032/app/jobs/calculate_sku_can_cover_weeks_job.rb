# frozen_string_literal: true

class CalculateSkuCanCoverWeeksJob < ApplicationJob
  queue_as :default

  def perform
    sku_quantity_hash = {}

    MagicBean::Order.includes(:order_items).paid.where(created_at: 7.days.ago.beginning_of_day..Time.current).each do |order|
      order.order_items.each do |order_item|
        sku_quantity_hash["#{order_item.stock_keeping_unit_id}"] ||= 0
        sku_quantity_hash["#{order_item.stock_keeping_unit_id}"] += order_item.quantity
      end

      (order.gifts_properties || []).each do |gift|
        sku_quantity_hash["#{gift["stock_keeping_unit_id"]}"] ||= 0
        sku_quantity_hash["#{gift["stock_keeping_unit_id"]}"] += gift["quantity"]
      end

      (order.pool_gifts_properties || []).each do |gift|
        sku_quantity_hash["#{gift["stock_keeping_unit_id"]}"] ||= 0
        sku_quantity_hash["#{gift["stock_keeping_unit_id"]}"] += gift["quantity"]
      end
    end

    MagicBean::StockKeepingUnit.ransack(item_ae_drop_shipper_eq: false).result.find_each do |sku|
      sales_count = sku_quantity_hash["#{sku.id}"]
      # FIXME: 每个sku都会查一遍限时优惠库存，这里会有性能问题
      sku_total_quantity = sku.quantity + sku.current_time_limited_promotion_price&.reserved_quantity.to_i

      # 过去七天有销量，可覆盖周数 = (原價庫存 + 限時優惠庫存) / 過去下單時間7天的銷量 (包含贈品) 精確到小數點後兩位
      # 过去七天无销量，且原價庫存 + 限時優惠庫存 == 0，则可覆盖周数为0
      # 过去七天无销量，且原價庫存 + 限時優惠庫存 != 0，则可覆盖周数为nil
      can_cover_weeks = if sales_count
                          (sku_total_quantity / sales_count.to_f).round(2)
                        elsif sku_total_quantity.zero?
                          0
                        else
                          nil
                        end
      sku.update_columns can_cover_weeks: can_cover_weeks
    end
  end
end
