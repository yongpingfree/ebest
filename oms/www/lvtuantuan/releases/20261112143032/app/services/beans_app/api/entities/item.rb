# frozen_string_literal: true

module BeansApp::API::Entities
  class Item < SimpleItem
    expose :tag_list
    expose :buy_quota
    expose :buy_quota_days
    expose :shared_description
    expose :item_type, documentation: { desc: "商品类型: { normal: '正常售卖' }" }
    expose :is_liked, documentation: { type: Grape::API::Boolean }
    expose :main_images
    expose :detail_images
    expose :detail_video
    expose :human_storage_method, documentation: { desc: "存储方式" }
    expose :qa_and_guarantee_image
    expose :qa_and_guarantee_web_image
    expose :on_sale_sku_options, as: :sku_options
    expose :share_cover
    expose :on_sale_skus, as: :stock_keeping_units, using: BeansApp::API::Entities::StockKeepingUnit
    expose :item_display_comments, as: :comments, using: BeansApp::API::Entities::SimpleComment
    expose :top_left_item_tag_icon, documentation: { desc: "左上角标签图标" }
    expose :maximun_strikethrough_price_in_yuan, documentation: { desc: "最大划线价" }

    def is_liked
      current_user.present? && current_user.like_item?(object)
    end

    def top_left_item_tag_icon
      if options[:active_top_left_item_hash]
        options[:active_top_left_item_hash].find { |_, item_ids| item_ids.include?(object.id) }&.first
      else
        object.active_top_left_item_tag_icon
      end
    end

    expose :sub_title
    expose :price_range
    expose :min_price
    expose :max_price
    expose :sales_count
    expose :quantity
    expose :comments_count
    expose :item_type
    expose :delivery_type
    expose :current_store_can_buy
    expose :active_groupon_activity, using: BeansApp::API::Entities::GrouponActivity
    expose :earliest_delivery_start_at
    expose :earliest_delivery_end_at
    expose :earliest_delivery_wday
    expose :delivery_text
    expose :advance_on?, as: :is_advance_on
    expose :start_selling_at
    expose :item_banner, using: BeansApp::API::Entities::ItemBanner

    def earliest_delivery_start_at
      nil
    end

    def earliest_delivery_end_at
      nil
    end

    def earliest_delivery_wday
      nil
    end

    def item_earliest_delivery_time
      @item_earliest_delivery_time ||= object.calculate_earliest_delivery_time(Time.current, current_postal_code, current_suburb)
    end

    def current_store_can_buy
      true
    end

    def delivery_text
      if current_store_can_buy
        ""
      else
        I18n.t("grape.delivery.no_delivery")
      end
    end
  end
end
