# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SkuWithNotSyncedQuantity < SimpleStockKeepingUnit
    expose :not_synced_quantity
    expose :gift_not_synced_quantity
    expose :new_user_price_in_cent
    expose :new_user_price_in_yuan
    expose :new_user_buy_quota
    expose :current_time_limited_promotion_price, using: BeansAdmin::API::Entities::TimeLimitedPromotionPrice
    expose :sku_level
    expose :gmv_sku_level
    expose :gp_sku_level
    expose :can_cover_weeks
    expose :average_stars

    def not_synced_quantity
      return 0 if options[:item]&.ae_drop_shipper || !object.id?
      
      # 普通订单待同步数量
      # 待同步数量只拿pending的订单，不拿confirmed
      normal_quantity = MagicBean::OrderItem.where(
        order_id: MagicBean::Order.paid.where(sync_status: :pending).where("delivery_date >= ?", Date.current.to_s).select(:id),
        stock_keeping_unit_id: object.id
      ).sum(:quantity)

      # shopline订单待同步数量
      shopline_quantity = options[:sale_quantities]&.dig(object.no).to_i

      normal_quantity + shopline_quantity
    end

    # AE SKU非常多，该方法在生产环境耗时3s，到时AE产品接口特别慢
    def gift_not_synced_quantity
      return 0 if options[:item]&.ae_drop_shipper || !object.id?
      quantity = 0

      MagicBean::Order.where.not(gifts_properties: nil).where("EXISTS (SELECT FROM json_array_elements(orders.gifts_properties) gift_element WHERE (gift_element->>'stock_keeping_unit_id')::int = #{object.id})")
        .or(MagicBean::Order.where.not(pool_gifts_properties: nil).where("EXISTS (SELECT FROM json_array_elements(orders.pool_gifts_properties) pool_gift_element WHERE (pool_gift_element->>'stock_keeping_unit_id')::int = #{object.id})"))
        .paid.where("delivery_date >= ?", Date.current.to_s).where(sync_status: :pending)
        .each do |order|
          ((order.gifts_properties || []) + (order.pool_gifts_properties || [])).each do |gift|
            if gift["stock_keeping_unit_id"] == object.id
              quantity += gift["quantity"]
            end
          end
      end

      quantity
    end

    def average_stars
      stars = MagicBean::Comment.where(commentable_type: "MagicBean::OrderItem", stock_keeping_unit_id: object.id).show.average(:stars).to_f.round(2)
      stars.zero? ? nil : stars
    end
  end
end
