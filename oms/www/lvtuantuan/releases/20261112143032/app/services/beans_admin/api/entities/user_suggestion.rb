# frozen_string_literal: true
module BeansAdmin::API::Entities
  class UserSuggestion < ::CommonEntities::Model
    expose :content
    expose :reply
    expose :replied_at
    expose :status
    expose :channel
    expose :user, using: ::BeansAdmin::API::Entities::User
    expose :images
  end
end
