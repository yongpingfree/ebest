# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleCouponAutoAssignment < ::CommonEntities::Model
    expose :assign_type, documentation: { type: String, values: ->() { MagicBean::CouponAutoAssignment.assign_types.keys }, desc: "发券类型" }
    expose :start_date, documentation: { desc: "开始日期" }
    expose :end_date, documentation: { desc: "结束日期" }
    expose :last_assigned_at
    expose :assign_users, using: BeansAdmin::API::Entities::User
    expose :coupon_templates, using: BeansAdmin::API::Entities::SimpleCouponTemplate
  end
end
