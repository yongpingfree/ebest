# frozen_string_literal: true

module OrderConcern
  module PreferentialPool
    extend ActiveSupport::Concern

    included do
      # constants

      # concerns

      # attr related macros

      # association macros

      # validation macros

      # callbacks
      before_validation :set_pool_gifts_properties, :set_pool_coupon_template_ids, on: :create

      # other macros

      # scopes

      # class methods

      # instance methods
    end

    def set_pool_gifts_properties
      return if active_pools.blank? || active_pools["gift"].blank?

      self.pool_gifts_properties = active_pools["gift"].map do |pool|
        # 把购物车中属于优惠池 SKU 的购买数量加起来，计算连续赠送
        max_quantity = 0
        order_items.each do |oi|
          max_quantity += oi.quantity if oi.stock_keeping_unit_id.in?(pool["sku_ids"])
        end

        order_items_attributes = []
        pool["preferences"]["skus"].each do |sku|
          stock_keeping_unit = MagicBean::StockKeepingUnit.find_by(id: sku["sku_id"])

          # 把不存在及无库存的过滤掉
          next if stock_keeping_unit.blank? || stock_keeping_unit.quantity.zero?

          gift_quantity = sku["quantity"]
          if pool["preferences"]["gift_cumulative"]
            # 多次赠送时，假设配置是買2送1，則用戶買4送2，買6送3；以此类推
            gift_quantity = (max_quantity / pool["at_least_quantity"]) * sku["quantity"]
          end
          order_item_attribute = stock_keeping_unit.to_order_item_json(gift_quantity, nil, nil, true).first
          order_item_attribute["free_shipping"] = stock_keeping_unit.item_free_shipping
          order_item_attribute["gift_card_enabled"] = stock_keeping_unit.item_gift_card_enabled
          order_item_attribute["coupon_enabled"] = stock_keeping_unit.item_coupon_enabled
          order_item_attribute["price_in_yuan"] = stock_keeping_unit.price_in_yuan
          order_item_attribute["no"] = stock_keeping_unit.no
          order_item_attribute["notification_quantity"] = pool["preferences"]["notification_quantity"]
          order_item_attribute["notification_emails"] = pool["preferences"]["notification_emails"]
          order_item_attribute["preferential_pool_id"] = pool["id"]
          order_items_attributes << order_item_attribute
        end
        order_items_attributes
      end.flatten
    end

    def set_pool_coupon_template_ids
      return if active_pools.blank? || active_pools["coupon_template"].blank?

      self.pool_coupon_template_ids = active_pools["coupon_template"].map { |pool| pool["preferences"]["coupon_template_ids"] }.flatten
    end

    def pool_coupon_template_properties
      return [] if active_pools["coupon_template"].blank?
      # 需要展示重复优惠券
      active_pools["coupon_template"].map do |pool|
        MagicBean::CouponTemplate.where(id: pool["preferences"]["coupon_template_ids"]).as_json(except: [:created_at, :updated_at])
      end.flatten
    end
  end
end
