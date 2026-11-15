# frozen_string_literal: true

module BeansApp::API::Entities
  class GrouponOrder < ::CommonEntities::Model
    expose :user_nickname, as: :nickname
    expose :user_avatar, as: :avatar do |object|
      object.user_avatar.presence || default_avatar
    end
    expose :is_not_paid?, as: :is_not_paid
  end
end
