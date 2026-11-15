# frozen_string_literal: true
module BeansAdmin::API::Entities
  class SimpleCustomList < ::CommonEntities::Model
    expose :kind, documentation: { type: String, desc: "列表类型" }
    expose :item_ids, documentation: { type: Array[Integer], desc: "商品列表", documentation: { param_type: "body" } }
    translate_expose :title, documentation: { type: String, desc: "标题", documentation: { param_type: "body" } }
    expose :remark, documentation: { type: String, desc: "备注", documentation: { param_type: "body" } }
    expose :as_category, documentation: { type: Grape::API::Boolean, desc: "作为分类", documentation: { param_type: "body" } }
    expose :position, documentation: { type: Integer, desc: "权重", documentation: { param_type: "body" } }
    expose :icon, documentation: { type: Integer, desc: "图标" }
    expose :bg_color, documentation: { type: String, desc: "背景色" }
    expose :show_discount_rate, documentation: { type: Grape::API::Boolean, desc: "是否显示折扣比" }
    expose :items_shuffled, documentation: { type: Grape::API::Boolean, desc: "打乱产品排序" }
    expose :same_day_delivery
    expose :same_day_delivery_title
    expose :store_name
    expose :parent_category_id
    expose :parent_category_name
    expose :ae_drop_shipper
  end
end
