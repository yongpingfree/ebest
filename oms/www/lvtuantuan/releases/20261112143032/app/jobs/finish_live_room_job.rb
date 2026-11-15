# frozen_string_literal: true

class FinishLiveRoomJob < ApplicationJob
  queue_as :default

  def perform(id)
    live_room = MagicBean::LiveRoom.find_by id: id
    if live_room && live_room.may_finish? &&
        (Time.current - live_room.start_at) >= MagicBean::LiveRoom::LIVE_DEFAULT_DURATION
      live_room.finish!
    end
  end
end
