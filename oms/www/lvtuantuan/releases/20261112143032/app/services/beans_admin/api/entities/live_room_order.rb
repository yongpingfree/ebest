# frozen_string_literal: true
module BeansAdmin::API::Entities
  class LiveRoomOrder < ::CommonEntities::Model
    expose :order, using: Order
    expose :user, using: User
    expose :user_id
  end
end
