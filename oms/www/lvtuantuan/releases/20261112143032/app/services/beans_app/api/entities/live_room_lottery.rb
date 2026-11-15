# frozen_string_literal: true

module BeansApp::API::Entities
  class LiveRoomLottery < ::CommonEntities::Model
    expose :name
    expose :duration_in_minutes
    expose :luck_limit
    expose :remark
    expose :award_cover
    expose :finished_at
    expose :state
    expose :draw_method, documentation: { desc: "comment: 评论参与抽奖，click: 点击抽奖箱参与抽奖" }
    expose :drawed, documentation: { desc: "是否已参与当前抽奖" }

    def drawed
      if (current_user.present? && object.live_room.current_lottery_id == object.id)
        object.live_room.current_lottery_users_set.include?(current_user.id)
      else
        false
      end
    end
  end
end
