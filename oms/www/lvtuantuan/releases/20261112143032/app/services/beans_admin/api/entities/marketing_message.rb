# frozen_string_literal: true

module BeansAdmin::API::Entities
  class MarketingMessage < ::CommonEntities::Model
    expose :store_id
    expose :admin_user_id
    expose :user_ids
    expose :manual_user_ids
    expose :sms_platform
    expose :users_count do |message, _options|
      message.user_ids&.size.to_i
    end
    # 列表/详情只需要展示前几条, 大名单全量输出会拖垮接口, 全量走 /marketing_messages/:id/users
    expose :users, using: BeansAdmin::API::Entities::User do |message, _options|
      message.users.limit(20)
    end
    expose :manual_users, using: BeansAdmin::API::Entities::User do |message, _options|
      message.manual_users.limit(20)
    end
    expose :admin_user, using: MinimalAdminUser
    expose :store, using: SimpleStore
    expose :content
    expose :state
    expose :push_at
  end
end
