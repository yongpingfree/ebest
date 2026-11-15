# frozen_string_literal: true

module BeansApp::API::Entities
  class SimpleComment < ::CommonEntities::Model
    expose :content
    expose :user_nickname do |object|
      object&.user&.origin_nickname.presence || object&.user&.nickname
    end
    expose :user_avatar do |object|
      object&.user&.origin_avatar.presence || default_avatar
    end
    expose :images
    expose :stars
    expose :item, using: BeansApp::API::Entities::SimpleItem
    expose :order_id

    def order_id
      object&.commentable&.order_id if object.commentable_type == "MagicBean::OrderItem"
    end
  end
end
