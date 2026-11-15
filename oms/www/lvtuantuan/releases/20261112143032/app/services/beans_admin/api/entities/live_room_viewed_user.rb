# frozen_string_literal: true
module BeansAdmin::API::Entities
  class LiveRoomViewedUser < ::CommonEntities::Model
    expose :user_nickname
    expose :user_id
  end
end
