# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleUser < ::CommonEntities::Model
    expose :nickname do |object|
      object.origin_nickname.presence || object.nickname
    end
    expose :gender, documentation: { type: :integer } do |object|
      object.origin_gender.presence || object.gender
    end
    expose :open_id
    expose :app_open_id
    expose :is_blocked
    expose :avatar do |object|
      object.origin_avatar.presence || object.avatar.presence || default_avatar
    end
    expose :last_visit_at
    expose :last_visit_ip
    expose :current_visit_at
    expose :current_visit_ip
    expose :is_host, documentation: { desc: "是否主播" }
    expose :deleted_by_user_at, documentation: { desc: "注销时间" }
    expose :deleted_by_user?, as: :deleted_by_user, documentation: { desc: "是否注销" }
    expose :sign_up_channel
    expose :accept_marketing_message
  end
end
