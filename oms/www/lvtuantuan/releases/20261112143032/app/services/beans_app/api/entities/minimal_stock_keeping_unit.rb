# frozen_string_literal: true

# 不返回sku property_text, 支持传item
module BeansApp::API::Entities
  class MinimalStockKeepingUnit < ::CommonEntities::Model
    expose :vids
    expose :quantity
    expose :original_price_in_cent
    expose :price_in_cent do |instance, _|
      prices = instance.final_price(options[:item_quantity])
      if options[:is_new_user] && instance.new_user_price_in_cent.to_i.positive? && prices.first > instance.new_user_price_in_cent
        instance.new_user_price_in_cent
      else
        prices.first
      end
    end
    expose :price_in_yuan do |instance, _|
      prices = instance.final_price(options[:item_quantity])
      if options[:is_new_user] && instance.new_user_price_in_cent.to_i.positive? && prices.first > instance.new_user_price_in_cent
        instance.new_user_price_in_yuan
      else
        prices.last
      end
    end
    expose :strikethrough_price_in_cent
    expose :strikethrough_price_in_yuan
    expose :weight_in_gram
    expose :cover, as: :image
    expose :item_id
    expose :title do |instance, _|
      (options[:item] || instance)&.title
    end
    expose :item_type do |instance, _|
      (options[:item] || instance)&.item_type
    end
    expose :listing_type do |instance, _|
      (options[:item] || instance)&.listing_type
    end
    expose :delivery_type do |instance, _|
      (options[:item] || instance)&.delivery_type
    end
    expose :is_virtual do |instance, _|
      (options[:item] || instance)&.is_virtual
    end
    expose :show_on_sale_soon_tag do |instance, _|
      (options[:item] || instance)&.show_on_sale_soon_tag
    end
    expose :is_on_sale, as: :on_sale
    expose :height_in_cm, documentation: { type: Float, desc: "高度" }
    expose :width_in_cm, documentation: { type: Float, desc: "宽度" }
    expose :length_in_cm, documentation: { type: Float, desc: "长度" }
    expose :barcode, documentation: { type: Integer, desc: "条形码" }
    expose :current_store_can_buy
    expose :delivery_weekdays, documentation: { desc: "可配送星期数，周日是0，周一至周六是 1 ~ 6，前端需手动排序", type: Array[String] } do |instance, _|
      (options[:item] || instance)&.delivery_weekdays
    end
    expose :not_eligible_for_free_gift, as: :item_not_eligible_for_free_gift
    expose :gift_card_enabled, as: :item_gift_card_enabled
    expose :coupon_enabled, as: :item_coupon_enabled
    expose :free_shipping, as: :item_free_shipping
    # # 前端组件需要返回没item前缀
    expose :not_eligible_for_free_gift
    expose :gift_card_enabled
    expose :coupon_enabled
    expose :free_shipping
    expose :freight_type do |instance, _|
      (options[:item] || instance)&.freight_type
    end
    expose :top_left_corner_tag_image do |instance, _|
      (options[:item] || instance)&.top_left_corner_tag_image
    end
    expose :ae_drop_shipper, documentation: { desc: "是否AE跨境购" } do |instance, _|
      (options[:item] || instance)&.ae_drop_shipper
    end

    # 为了减少购物车商品 N+1 的是否已订阅到货通知的查询，通过传参方式来计算该状态
    expose :is_subscribe_sku_in_stock_notice, documentation: { desc: "是否已订阅到货通知", type: Grape::API::Boolean } do |instance, options|
      (options[:pending_sku_ids] || []).include?(instance.id)
    end

    expose :top_left_item_tag_icon, documentation: { type: Integer, desc: "左上角标签图标" }
    expose :is_new_product
    expose :is_box_regulation

    def current_store_can_buy
      true
    end

    def original_price_in_cent
      object.price_in_cent
    end

    def not_eligible_for_free_gift
      options[:item] ? options[:item].not_eligible_for_free_gift : object.item_not_eligible_for_free_gift
    end

    def gift_card_enabled
      options[:item] ? options[:item].gift_card_enabled : object.item_gift_card_enabled
    end

    def coupon_enabled
      options[:item] ? options[:item].coupon_enabled : object.item_coupon_enabled
    end

    def free_shipping
      options[:item] ? options[:item].free_shipping : object.item_free_shipping
    end

    def is_on_sale
      object.is_on_sale?(options[:item])
    end

    def top_left_item_tag_icon
      # 为了避免有的地方漏传active_top_left_item_hash导致列表加载慢，没传的场景先不处理
      if options[:active_top_left_item_hash]
        options[:active_top_left_item_hash].find { |_, item_ids| item_ids.include?(object.item_id) }&.first
      end
    end

    def is_new_product
      (options[:item] || object.item).is_new_product?
    end
  end
end
