# frozen_string_literal: true

module BeansApp::API::Entities
  class MinimalItem < ::CommonEntities::Model
    # TODO: 商品列表要可能需要展示优惠价，这里跟客户确认一下先
    expose :title
    expose :sub_title
    expose :short_title
    expose :custom_price_in_yuan, as: :price_in_yuan
    expose :strikethrough_price_in_yuan
    expose :new_user_price_in_yuan
    expose :discount_rate
    expose :cover
    expose :top_left_corner_tag_image
    expose :is_on_sale?, as: :on_sale
    expose :show_on_sale_soon_tag
    expose :active_groupon_activity_hash, as: :active_groupon_activity
    expose :channels
    expose :brand_id
    expose :quantity
    expose :delivery_type
    expose :is_virtual
    expose :is_liked
    expose :coupon_enabled, documentation: { desc: "是否可使用优惠券" }
    expose :gift_card_enabled, documentation: { desc: "是否可使用礼品券" }
    expose :free_shipping, documentation: { desc: "是否参与包邮计划" }
    expose :not_eligible_for_free_gift, documentation: { desc: "是否不参与满品" }
    expose :gift_only, documentation: { desc: "只能用做赠品" }
    expose :ae_drop_shipper, documentation: { desc: "是否AE跨境购" }
    expose :ae_delivery_date, documentation: { desc: "AE跨境购商品配送日期" }
    expose :ae_delivery_date_desc, documentation: { desc: "AE跨境购商品配送描述" }
    expose :ae_estimated_delivery_days, documentation: { desc: "AE跨境购商品预计运输日期" }
    expose :top_left_item_tag_icon, documentation: { desc: "左上角标签图标" }
    expose :hot_sell_ranking, documentation: { desc: "热卖榜排名" }
    expose :hot_sell_config_id, documentation: { desc: "热卖榜配置ID" }
    expose :is_new_product?, as: :is_new_product
    expose :category_id
    expose :category_name
    expose :is_seasonal
    expose :is_fresh_daily
    expose :is_presell
    expose :presell_end_at
    expose :presell_dispatch_on, documentation: { desc: "预售可派送最早日期" }
    expose :storage_method
    expose :display_expiration_date?, as: :display_expiration_date, documentation: { type: Grape::API::Boolean, desc: "是否显示过期日期" }
    expose :expiration_date, documentation: { type: Date, desc: "过期日期" }
    expose :expiration_reminder_before_n_days, documentation: { type: Integer, desc: "提前n天提示过期日期弹窗" }
    expose :delivery_weekdays, documentation: { desc: "可配送星期数，周日是0，周一至周六是 1 ~ 6，前端需手动排序", type: Array[String] }
    expose :in_time_limited_promotion?, as: :in_time_limited_promotion, documentation: { desc: "是否正在进行限时优惠促销" }
    expose :has_exclusive_coupons, documentation: { type: Grape::API::Boolean, desc: "是否有专属优惠券" }
    expose :buy_n_discount_quantity, documentation: { desc: "买N折扣数量" }
    expose :preferential_pool_info, documentation: { desc: "产品优惠池信息" }
    expose :allow_view_same_tag_items_tag, documentation: { desc: "允许搜索同标签商品的标签" }

    def active_groupon_activity_hash
      @activity =
        if options[:groupon_activities]
          options[:groupon_activities].find { |activity| activity.item_id == object.id }
        else
          object.groupon_activities.published.going.first
        end

      @activity ? { id: @activity.id, min_price: @activity.min_price } : nil
    end

    def is_on_sale?
      object.on_sale? && object.channel_match?(ebest_channel)
    end

    def discount_rate
      if object.strikethrough_price_in_cent? && object.strikethrough_price_in_cent > custom_price_in_cent
        # 折扣最低1%，最高99%, 低于1%不显示折扣
        rate = ((object.strikethrough_price_in_cent - custom_price_in_cent).to_f * 100 / object.strikethrough_price_in_cent).round
        rate = 99 if rate == 100
        rate.zero? ? nil : I18n.t("grape.items.discount_rate_text", rate: rate)
      else
        nil
      end
    end

    def custom_price_in_cent
      return object.price_in_cent unless object.new_user_price_in_cent.to_i.positive?
      options[:is_new_user] ? object.new_user_price_in_cent : object.price_in_cent
    end

    def custom_price_in_yuan
      return object.price_in_yuan unless object.new_user_price_in_cent.to_i.positive?
      options[:is_new_user] ? object.new_user_price_in_yuan : object.price_in_yuan
    end

    def is_liked
      (options[:like_item_ids] || []).include? object.id
    end

    def top_left_item_tag_icon
      # 为了避免有的地方漏传active_top_left_item_hash导致列表加载慢，没传的场景先不处理
      if options[:active_top_left_item_hash]
        options[:active_top_left_item_hash].find { |_, item_ids| item_ids.include?(object.id) }&.first
      end
    end

    def has_exclusive_coupons
      return false unless object.coupon_enabled
      if options[:exclusive_coupon_item_info].present?
        options[:exclusive_coupon_item_info][:item_ids].include?(object.id) || options[:exclusive_coupon_item_info][:category_ids].include?(object.parent_category_id) || options[:exclusive_coupon_item_info][:sub_category_ids].include?(object.category_id) || options[:exclusive_coupon_item_info][:brand_ids].include?(object.brand_id)
      else
        false
      end
    end

    def buy_n_discount_quantity
      options[:buy_n_discount_item_info][object.id] if options[:buy_n_discount_item_info].present?
    end

    # 产品优惠池信息
    def preferential_pool_info
      if options[:preferential_pool_item_infos].present?
        target_info = options[:preferential_pool_item_infos].find { |info| info[:item_ids].include?(object.id) }
        { kind: target_info[:kind], title: target_info[:title] } if target_info
      end
    end

    # 允许搜索同标签商品的标签
    def allow_view_same_tag_items_tag
      if options[:allow_view_same_tag_items_info].present?
        target_info = options[:allow_view_same_tag_items_info].find { |_, info| info[:item_ids].include?(object.id) }
        { tag_id: target_info.first, tag_name: target_info.last[:item_tag_name] } if target_info
      end
    end
  end
end
