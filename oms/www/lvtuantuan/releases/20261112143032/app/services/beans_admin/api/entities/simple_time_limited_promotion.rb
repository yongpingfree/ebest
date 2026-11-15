# frozen_string_literal: true
module BeansAdmin::API::Entities
  class SimpleTimeLimitedPromotion < ::CommonEntities::Model
    expose :title, documentation: { type: String, desc: "标题" }
    expose :start_at, documentation: { type: DateTime, desc: "开始时间" }
    expose :end_at, documentation: { type: DateTime, desc: "结束时间" }
    expose :enabled, documentation: { type: Grape::API::Boolean, desc: "是否启用" }
    expose :can_edit
    expose :state
    expose :store_name
    expose :save_qty_to_promotion_price, documentation: { type: Grape::API::Boolean, desc: "限时优惠活动期间添加库存到优惠库存" }
  end
end
