# frozen_string_literal: true

module BeansAdmin::API::Entities
  class MobileBlacklist < ::CommonEntities::Model
    expose :mobile
    expose :enabled, documentation: { type: Grape::API::Boolean }
    expose :live_comment_disabled, documentation: { type: Grape::API::Boolean }
    expose :live_lottery_disabled, documentation: { type: Grape::API::Boolean }
    expose :push_notification_disabled, documentation: { type: Grape::API::Boolean }
    expose :marketing_sms_disabled, documentation: { type: Grape::API::Boolean }
    expose :order_disabled, documentation: { type: Grape::API::Boolean }
    expose :started_at, documentation: { type: DateTime }
    expose :ended_at, documentation: { type: DateTime }
  end
end
