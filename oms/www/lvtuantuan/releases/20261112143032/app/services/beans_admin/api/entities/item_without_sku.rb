# frozen_string_literal: true

module BeansAdmin::API::Entities
  class ItemWithoutSku < SimpleItem
    expose :share_cover
    expose :qrcode
    expose :comment_tag_list, documentation: { desc: "评论标签" }
    expose :comments_count
    translate_expose :shared_description, documentation: { desc: "分享商品时的描述" }
    expose :main_images, documentation: { type: Array[String], desc: "商品主图链接列表", documentation: { param_type: "body" } }
    expose :detail_images, documentation: { type: Array[String], desc: "商品详情图链接列表", documentation: { param_type: "body" } }
    expose :detail_video, documentation: { type: String, desc: "商品详情视频连接" }
    expose :likes_count, documentation: { type: Integer, desc: "实际收藏数（只读）" }
    expose :likes_count_offset, documentation: { type: Integer, desc: "基础收藏数" }
    expose :monthly_sales_count_offset, documentation: { type: Integer, desc: "基础月销量数" }
    expose :sales_count_offset, documentation: { type: Integer, desc: "基础销量数" }
    expose :total_likes_count, documentation: { type: Integer, desc: "总收藏数" }
    translate_expose :description, documentation: { type: String, desc: "描述" }
    expose :ae_h5_description, documentation: { type: String, desc: "跨境购商品描述" }
    expose :freight_type, documentation: { desc: "运费类型:1. freight_fixed（统一运费）；2. freight_template（运费模版）" }
    expose :default_freight_template_ids, documentation: { type: Array[Integer], desc: "运费模版ID" }
    expose :merchant_delivery_freight_template_id, documentation: { type: Integer, desc: "商家配送运费模版ID" }
    expose :express_freight_template_id, documentation: { type: Integer, desc: "邮寄运费模版ID" }
    expose :self_pick_freight_template_id, documentation: { type: Integer, desc: "自提运费模版ID" }
    expose :default_freight_templates
    expose :fixed_freight, documentation: { type: Integer, desc: "统一运费（单位：分）" }
    expose :fixed_freight_in_yuan
    expose :fixed_freight_cost_in_yuan
    expose :qa_and_guarantee_id, documentation: { type: Integer, desc: "答疑&保障模版ID" }
    expose :qa_and_guarantee, using: BeansAdmin::API::Entities::QaAndGuarantee
    expose :cutoff_times, using: BeansAdmin::API::Entities::CutoffTime
    # 订单详情页实时计算月销量
    expose :calculate_actual_monthly_sales_count, as: :actual_monthly_sales_count
    expose :monthly_sales_count
    expose :tag_list, documentation: { desc: "标签" }
    expose :can_show_normal_orders
    expose :can_show_groupon_orders
    expose :can_show_virtual_orders
    expose :pending_comments_count
    expose :storage_method
    expose :ingredient
    expose :delivery_weekdays
    expose :can_edit_item_type
    expose :is_seasonal
    expose :is_fresh_daily
    expose :item_tag_names

    def default_freight_templates
      # includes :default_freight_templates
      object.default_freight_templates.includes(:translations).map { |template| { id: template.id, name: template.name, delivery_type: template.delivery_type } }
    end

    def can_edit_item_type
      object.pending?
    end

    def item_tag_names
      object.item_tags.includes(:translations).map(&:name)
    end
  end
end
