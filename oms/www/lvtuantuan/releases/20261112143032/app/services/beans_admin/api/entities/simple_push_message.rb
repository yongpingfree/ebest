# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimplePushMessage < ::CommonEntities::Model
    expose :admin_user_id
    expose :title
    expose :content
    expose :image
    expose :push_at
    expose :state
    expose :uv
    expose :pv
    expose :store_id
    expose :kind
    expose :path_customized
    expose :path_customized_id
    expose :path_customized_type
    expose :user_locales
    expose :admin_user, using: MinimalAdminUser
    expose :store, using: SimpleStore
  end
end
