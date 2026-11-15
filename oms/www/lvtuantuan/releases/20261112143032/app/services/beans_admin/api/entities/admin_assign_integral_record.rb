# frozen_string_literal: true

module BeansAdmin::API::Entities
  class AdminAssignIntegralRecord < ::CommonEntities::Model
    expose :admin_user, with: BeansAdmin::API::Entities::AdminUser
    expose :member, with: BeansAdmin::API::Entities::Member
    expose :content
  end
end
