# frozen_string_literal: true

class SaveSkuInventorySnapshotEveryWeekJob < ApplicationJob
  queue_as :default

  def perform
    # 每周一把两周前的快照数据删除
    MagicBean::SkuInventorySnapshot.where("record_date <= ?", Date.current - 2.week).delete_all

    # 先查出所有显示优惠的sku的reserved_quantity
    promotion_skus_hash = {}
    MagicBean::TimeLimitedPromotion.includes(:time_limited_promotion_prices).active.each do |promotion|
      promotion.time_limited_promotion_prices.each do |promotion_price|
        promotion_skus_hash[promotion_price.stock_keeping_unit_id] = promotion_price.reserved_quantity.to_i
      end
    end
  
    # 获取上周一0点~本周一0点所有已支付的订单的赠品/优惠池赠品数量
    time_range = ((Date.current - 1.week).beginning_of_day)..(Date.current.beginning_of_day)
    collection = MagicBean::Order.where.not(gifts_properties: nil).or(MagicBean::Order.where.not(pool_gifts_properties: nil)).paid.where(created_at: time_range)

    gift_hash = {}

    collection.map do |order|
      (order.gifts_properties || []).each do |gift|
        gift_hash[gift["stock_keeping_unit_id"]] ||= 0
        gift_hash[gift["stock_keeping_unit_id"]] += gift["quantity"]
      end

      (order.pool_gifts_properties || []).each do |gift|
        gift_hash[gift["stock_keeping_unit_id"]] ||= 0
        gift_hash[gift["stock_keeping_unit_id"]] += gift["quantity"]
      end
    end

    # 获取上周一0点~本周一0点所有sku销量
    sales_hash = MagicBean::OrderItem.where(order_id: MagicBean::Order.select(:id).paid.where(created_at: time_range)).group(:stock_keeping_unit_id).sum(:quantity)

    MagicBean::StockKeepingUnit.includes(:last_monday_inventory_snapshot).ransack(item_ae_drop_shipper_eq: false).result.find_each do |sku|
      current_reserved_quantity = promotion_skus_hash[sku.id].to_i

      snapshot = sku.sku_inventory_snapshots.find_or_initialize_by(record_date: Date.current)
      snapshot.quantity = sku.quantity
      snapshot.reserved_quantity = current_reserved_quantity
      snapshot.save

      # 上周一的有快照数据，才需要计算周转率
      if sku.last_monday_inventory_snapshot.present?
        # 计算周转率: (上週總銷量 + 滿贈 + 優惠池贈品數量)* 2 / (上周一0點庫存包括原價預留庫存 + 本周一0點庫存原價預留庫存 )
        total_quantity = sku.quantity + current_reserved_quantity + sku.last_monday_inventory_snapshot.reserved_quantity + sku.last_monday_inventory_snapshot.quantity
        sku.turnover_rate = total_quantity.zero? ? 0 : ((sales_hash[sku.id].to_i + gift_hash[sku.id].to_i) * 2 / total_quantity.to_f).round(2)
        sku.save(validate: false)
      end
    end
  end
end
