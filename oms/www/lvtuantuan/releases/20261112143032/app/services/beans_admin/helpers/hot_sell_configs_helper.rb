# frozen_string_literal: true

module BeansAdmin::Helpers
  module HotSellConfigsHelper
    def sku_ids_order_by_sales(hot_sell_config, ae_drop_shipper = false)
      #过去x天销量
      beginning_time = Time.current - hot_sell_config.last_x_days.days
      target_order_status = [:wait_seller_send_goods, :wait_buyer_confirm_goods, :trade_finished, :buyer_confirm_goods, :apply_refund, :risk_pay, :live_top_confirm]
      order_items_ransack_params = { store_id_eq: hot_sell_config.store_id, order_status_in: target_order_status, item_listing_type_eq: :online, item_ae_drop_shipper_eq: ae_drop_shipper, created_at_gteq: beginning_time, item_category_id_eq: hot_sell_config.category_id }
      order_items_ransack_params[:item_quantity_gt] = 0 if hot_sell_config.is_show_storage_on_sale

      # 普通订单销量计算
      all_item_sales_hash = MagicBean::OrderItem.ransack(order_items_ransack_params).result.group(:item_id).sum(:quantity).sort_by { |_, count| -count }.to_h

      # 不包含满赠和优惠池满赠时，可以直接返回
      return all_item_sales_hash.first(hot_sell_config.show_item_nums).to_h.keys unless hot_sell_config.contains_order_pool_gift || hot_sell_config.contains_order_gift

      # 全场满赠&优惠池满赠 销量计算
      order_ransack_params = { store_id_eq: hot_sell_config.store_id, status_in: target_order_status, created_at_gteq: beginning_time, ae_drop_shipper_eq: ae_drop_shipper }
      item_ransack_params = { category_id_eq: hot_sell_config.category_id, listing_type_eq: :online, ae_drop_shipper_eq: ae_drop_shipper, store_id_eq: hot_sell_config.store_id }
      item_ransack_params[:quantity_gt] = 0 if hot_sell_config.is_show_storage_on_sale

      gift_item_count_hash = {}
      MagicBean::Order.where.not(gifts_properties: nil).or(MagicBean::Order.where.not(pool_gifts_properties: nil)).ransack(order_ransack_params).result.find_each do |order|
        target_gifts = []
        target_gifts += (order.gifts_properties || []) if hot_sell_config.contains_order_gift
        target_gifts += (order.pool_gifts_properties || []) if hot_sell_config.contains_order_pool_gift
        target_gifts.each do |gift|
          gift_item_count_hash[gift["item_id"]] ||= 0
          gift_item_count_hash[gift["item_id"]] += gift["quantity"]
        end
      end

      # 将满足条件的产品销量加入到all_item_sales_hash中
      MagicBean::Item.ransack(item_ransack_params).result.where(id: gift_item_count_hash.keys).find_each do |item|
        all_item_sales_hash[item.id] ||= 0
        all_item_sales_hash[item.id] += gift_item_count_hash[item.id]
      end

      all_item_sales_hash.sort_by { |_, count| -count }.first(hot_sell_config.show_item_nums).to_h.keys
    end
  end
end
