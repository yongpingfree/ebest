# frozen_string_literal: true

module BeansApp::API::Entities
  class Comment < SimpleComment
    expose :tag_list
    expose :is_top
    expose :reply, using: BeansApp::API::Entities::Comment
    expose :is_liked, documentation: { type: Grape::API::Boolean }
    expose :likes_count

    def is_liked
      like_comment_ids = options[:like_comment_ids]
      if like_comment_ids.present?
        options[:like_comment_ids].include? object.id
      else
        current_user.present? && current_user.like_comment?(object)
      end
    end

    def order_id
      object.commentable&.order_id if object.commentable_type == "MagicBean::OrderItem"
    end
  end
end
