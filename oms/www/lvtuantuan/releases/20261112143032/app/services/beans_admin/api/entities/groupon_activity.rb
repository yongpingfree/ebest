# frozen_string_literal: true
module BeansAdmin::API::Entities
  class GrouponActivity < ::CommonEntities::Model
    expose :kind, documentation: { type: String, values: ["item", "sku"], desc: "商品类型" }
    expose :price_in_yuan
    expose :rules, documentation: { type: String, desc: "拼团规则" }
    expose :user_count, documentation: { type: Integer, desc: "拼团人数" }
    expose :start_at, documentation: { type: DateTime, desc: "开始时间" }
    expose :end_at, documentation: { type: DateTime, desc: "结束时间" }
    expose :enabled, documentation: { type: Grape::API::Boolean, desc: "是否发布拼团活动" }
    expose :item_id, documentation: { type: Integer, desc: "商品ID" }
    expose :item_title
    expose :editable?, as: :editable
    expose :is_real, documentation: { type: Boolean, desc: "是否真拼团" }
    expose :expired_hours, documentation: { type: Integer, desc: "拼团关闭时数" }
    expose :sku_groupons, using: BeansAdmin::API::Entities::SkuGroupon
    expose :wms_sync_type, documentation: { type: String, values: MagicBean::GrouponActivity.wms_sync_types.keys, desc: "类型" }
    expose :type, documentation: { type: String, values: ["MagicBean::NormalGrouponActivity", "MagicBean::BigGrouponActivity"], desc: "活动类型" }
  end
end
