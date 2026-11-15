# frozen_string_literal: true

module BeansAdmin::API::Entities
  class Comment < ::CommonEntities::Model
    expose :content
    expose :user_id
    expose :user_nickname do |object|
      object&.user&.origin_nickname.presence || object&.user&.nickname
    end
    expose :user_avatar do |object|
      object&.user&.origin_avatar.presence || default_avatar
    end
    expose :images
    expose :status
    expose :cover
    expose :is_top
    expose :stock_keeping_unit_id
    expose :properties_text
    expose :tag_list
    expose :item_id
    expose :item_title
    expose :reply_content
    expose :reply_id
    expose :stars
    expose :commentable_type
    expose :commentable_id
    expose :order_id
    expose :order_no
    expose :order_type
    
    def order
      object&.commentable&.order if object.commentable_type == "MagicBean::OrderItem"
    end

    def order_id
      order&.id
    end

    def order_no
      order&.no
    end

    def order_type
      order&.type
    end    
  end
end
