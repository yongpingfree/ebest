# frozen_string_literal: true

module BeansApp::API::Entities
  class SimpleUser < ::CommonEntities::Model
    expose :nickname do |object|
      object.origin_nickname.presence || object.nickname
    end
    expose :avatar do |object|
      object.origin_avatar.presence || object.avatar.presence || default_avatar
    end
  end
end
