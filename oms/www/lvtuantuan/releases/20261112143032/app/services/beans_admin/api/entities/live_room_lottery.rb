# frozen_string_literal: true

module BeansAdmin::API::Entities
  class LiveRoomLottery < ::CommonEntities::Model
    expose :live_room_id
    expose :name
    expose :duration_in_minutes
    expose :luck_limit
    expose :remark
    expose :state
    expose :award_cover
    expose :started_at
    expose :finished_at
    expose :draw_method
    expose :live_room_lottery_winning_users, using: LiveRoomLotteryWinningUser
  end
end
