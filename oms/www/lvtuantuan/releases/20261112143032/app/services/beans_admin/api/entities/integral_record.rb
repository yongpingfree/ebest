# frozen_string_literal: true

module BeansAdmin::API::Entities
  class IntegralRecord < ::CommonEntities::Model
    expose :integral, documentation: { type: String, desc: "积分" }
    expose :kind, documentation: { type: String, desc: "类型" }
    expose :available_integral, documentation: { type: String, desc: "可用积分" }
    expose :blocked_integral, documentation: { type: String, desc: "冻结积分" }
    expose :targetable_type, documentation: { type: String, desc: "目标类型" }
    expose :targetable, using: BeansAdmin::API::Entities::SimpleOrder, if: -> (instance, _) { instance.targetable_type == "MagicBean::Order" }
    expose :targetable, using: BeansAdmin::API::Entities::SimpleAfterSale, if: -> (instance, _) { instance.targetable_type == "MagicBean::AfterSale" }
    expose :targetable, using: BeansAdmin::API::Entities::Member, if: -> (instance, _) { instance.targetable_type == "MagicBean::Member" }
    expose :channel
  end
end
