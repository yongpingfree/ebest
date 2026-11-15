# frozen_string_literal: true

class LiveRoomViewedUserStatJob < ApplicationJob
  queue_as :orders # 使用优先级最高的 queue，以免统计 job 延时

  def perform(live_room_id)
    live_room = MagicBean::LiveRoom.find_by(id: live_room_id)

    live_room.count_real_time_viewed_user if live_room && live_room.live_state?
  end
end
