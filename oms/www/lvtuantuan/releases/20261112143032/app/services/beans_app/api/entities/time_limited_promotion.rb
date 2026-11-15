# frozen_string_literal: true
module BeansApp::API::Entities
  class TimeLimitedPromotion < ::CommonEntities::Model
    expose :title, documentation: { type: String, desc: "标题" }
    expose :start_at, documentation: { type: DateTime, desc: "开始时间" }
    expose :end_at, documentation: { type: DateTime, desc: "结束时间" }
    expose :enabled, documentation: { type: Grape::API::Boolean, desc: "是否启用" }
    expose :state
  end
end
