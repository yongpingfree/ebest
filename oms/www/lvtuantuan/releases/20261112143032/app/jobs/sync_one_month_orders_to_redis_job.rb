# frozen_string_literal: true

class SyncOneMonthOrdersToRedisJob < ApplicationJob
  queue_as :default

  def perform
    # 同步自派非次日达订单上限到redis
    MagicBean::Store.all.each do |store|
      Time.zone = store.current_time_zone
      (Date.current..(Date.current + 35.days)).each do |date|
        key = "store-#{store.id}-#{date}"
        # 先清除当天数据
        Rails.cache.redis.del key

        MagicBean::Order.merchant_delivery.trade_not_close.where.not(type: "MagicBean::SameDayDeliveryOrder").where(next_day_delivery: false, mark_for_orders_limit: true, store_id: store.id, delivery_date: date).group("receiver_properties").count.each do |address, order_count|
          Rails.cache.redis.hset key, address.to_json, order_count
        end

        # 计算非次日达订单数
        MagicBean::Order.merchant_delivery.where(store_id: store.id).last&.send :recalculate_merchant_orders_data, date
      end
      # 每天同步完把前一天数据清除
      Rails.cache.redis.del "store-#{store.id}-#{Date.current - 1.day}"
      Rails.cache.redis.del "store-#{store.id}-#{Date.current - 1.day}-addresses-count"

      # 同步全局配置中的订单地址数上限
      Rails.cache.redis.set "store-#{store.id}-orders-limit-every-day", store.site_config.merchant_delivery_orders_limit_every_day.to_i.abs
    end

    # 同步区域特定上限到redis
    MagicBean::DeliveryTime.all.each do |time|
      Time.zone = ApplicationRecord::TIME_ZONE
      (Date.current..(Date.current + 35.days)).each do |date|
        # 先清除当天数据
        Rails.cache.redis.keys("delivery-time-#{time.id}-#{date}-list-period-*").each do |key|
          Rails.cache.redis.del key
        end

        time.delivery_time_period_settings.each do |period_setting|
          MagicBean::Order.merchant_delivery.trade_not_close.where(delivery_time_id: time.id, delivery_time_period_setting_id: period_setting.id, delivery_date: date).group("receiver_properties").count.each do |address, order_count|
            key = "delivery-time-#{time.id}-#{date}-list-period-#{period_setting.id}"
            Rails.cache.redis.hset key, address.to_json, order_count
          end
        end

        # 计算次日达订单数
        MagicBean::Order.merchant_delivery.where(delivery_time_id: time.id).last&.send :recalculate_delivery_time_orders_data, date
      end

      # 由于delivery_time没有关联store, 假如墨尔本时区是20号，有的时区是19号，19号数据被清除的话会导致下单限制数量不正确，所以只清除前两天的数据
      Rails.cache.redis.keys("delivery-time-#{time.id}-#{Date.current - 2.day}-list-period-*").each do |key|
        Rails.cache.redis.del key
      end

      Rails.cache.redis.del "delivery-time-#{time.id}-#{Date.current - 2.day}-addresses-count"
      Rails.cache.redis.keys("delivery-time-#{time.id}-#{Date.current - 2.day}-period-*-addresses-count").each do |key|
        Rails.cache.redis.del key
      end
    end

    # 同步自提订单上限到redis
    MagicBean::SelfPickUp.all.each do |self_pick|
      Time.zone = self_pick.store.current_time_zone

      MagicBean::Order.self_pick.trade_not_close.where(self_pick_up_id: self_pick.id).where(delivery_date: Date.current..(Date.current + 35.days)).group(:delivery_date).count.each do |key, value|
        key = "self-pick-#{self_pick.id}-#{key}"
        Rails.cache.redis.set key, value
      end

      # 每天同步完把前一天数据清除
      Rails.cache.redis.del "self-pick-#{self_pick.id}-#{Date.current - 1.day}"
    end

    # 本地执行了perform_later连续执行perform_later, 发现如果不把time zone改回来是不会变回墨尔本的，所以在job最后再重置下时区
    Time.zone = ApplicationRecord::TIME_ZONE
  end
end
