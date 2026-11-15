# frozen_string_literal: true
module BeansApp::API::Entities
  class UserSuggestion < ::CommonEntities::Model
    expose :content
    expose :reply
    expose :replied_at
    expose :status
    expose :user_id
    expose :channel
    expose :images
  end
end
