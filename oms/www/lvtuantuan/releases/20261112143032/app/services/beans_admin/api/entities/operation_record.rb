# frozen_string_literal: true

module BeansAdmin::API::Entities
  class OperationRecord < ::CommonEntities::Model
    expose :admin_user, with: BeansAdmin::API::Entities::AdminUser
    expose :operatable_type do |object|
      if object.operatable_type == "MagicBean::Order"
        object.operatable.type
      else
        object.operatable_type
      end&.gsub("MagicBean::", "")&.underscore&.pluralize
    end
    expose :operatable_id
    expose :operatable_title
    expose :content
    expose :channel
  end
end
