# frozen_string_literal: true

module BeansAdmin::API::Entities
  class LiveRoomLotteryWinningUser < ::CommonEntities::Model
    expose :human_receiver_properties
    expose :user, using: BeansAdmin::API::Entities::SimpleUser
  end
end
