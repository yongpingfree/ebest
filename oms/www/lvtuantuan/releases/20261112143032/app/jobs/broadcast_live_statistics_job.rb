# frozen_string_literal: true

class BroadcastLiveStatisticsJob < ApplicationJob
  queue_as :default

  def perform(live_room_id)
    live_room = MagicBean::LiveRoom.find_by(id: live_room_id)
    if live_room
      data = {
        action: "statistics",
        data: live_room.app_statistics_data
      }
      ActionCable.server.broadcast(live_room.channel_name, data)
      if live_room.live_state?
        BroadcastLiveStatisticsJob.set(
          wait: MagicBean::LiveRoom::LIVE_STATISTICS_BROADCAST_INTERNAL
        ).perform_later(live_room_id)
      end
    end
  end
end
