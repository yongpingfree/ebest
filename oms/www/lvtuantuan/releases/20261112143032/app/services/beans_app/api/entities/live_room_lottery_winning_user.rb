# frozen_string_literal: true

module BeansApp::API::Entities
  class LiveRoomLotteryWinningUser < ::CommonEntities::Model
    expose :address_id
    expose :human_receiver_properties
    expose :live_room_lottery, using: BeansApp::API::Entities::LiveRoomLottery
  end
end
