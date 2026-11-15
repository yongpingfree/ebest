# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleItem < MinimalItem
    expose :no, documentation: { type: String, desc: "商品货号（为商品设置的外部编号）" }
    expose :item_type, documentation: { type: String, desc: "商品类型", values: MagicBean::Item.item_types.keys }
    expose :leader, documentation: { type: String, desc: "负责人" }
    expose :listing_type, documentation: { type: String, desc: "列表类型", values: MagicBean::Item.listing_types.keys }
    expose :brand_name, documentation: { desc: "品牌" }
    expose :brand_id, documentation: { desc: "品牌ID" }
    expose :sub_title
    expose :position
    expose :destroyable
    expose :category_name
    expose :category_id, documentation: { type: Integer, desc: "主分类 ID" }
    expose :parent_category_id
    expose :minor_category_name
    expose :minor_category_id, documentation: { type: Integer, desc: "次分类 ID" }
    expose :web_category_name
    expose :web_category_id, documentation: { type: Integer, desc: "网站分类主分类 ID" }
    expose :parent_web_category_id
    expose :minor_web_category_name
    expose :minor_web_category_id, documentation: { type: Integer, desc: "网站分类次分类 ID" }
    expose :quantity, documentation: { type: Integer, desc: "库存量" }
    expose :sales_count, documentation: { type: Integer, desc: "销量" }
    expose :display_sales_count, documentation: { type: Integer, desc: "销量数" }
    expose :buy_quota, documentation: { type: Integer, desc: "累计限购" }
    expose :buy_quota_days, documentation: { type: Integer, desc: "限购周期(天)" }
    expose :actual_monthly_sales_count
    expose :start_selling_at, documentation: { type: DateTime, desc: "开售时间"}
    expose :is_presell
    expose :presell_end_at, documentation: { type: DateTime, desc: "预售结束时间"}
    expose :presell_dispatch_on
    expose :latest_presell_dispatch_on
    expose :is_virtual
    expose :app_share_url
    expose :coupon_enabled, documentation: { type: Boolean, desc: "是否可用优惠券" }
    expose :store_name
    expose :production_place
    expose :allergen
    expose :serving_per_package
    expose :serving_size
    expose :free_shipping
    expose :gift_card_enabled
    expose :not_eligible_for_free_gift, documentation: { desc: "是否不参与满品" }
    expose :gift_only
    expose :ae_drop_shipper
    expose :shopline_synced?, as: :shopline_synced
    expose :ae_unsaleable
    expose :is_ae_choice

    def destroyable
      # 可能传过来是空的数组
      if options[:not_destroyable_item_ids].nil?
        object.destroyable?
      else
        options[:not_destroyable_item_ids].exclude? object.id
      end
    end
  end
end
