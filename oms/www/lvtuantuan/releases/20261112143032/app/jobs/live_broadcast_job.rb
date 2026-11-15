# frozen_string_literal: true

class LiveBroadcastJob < ApplicationJob
  queue_as :default

  def perform(live_room_id, data)
    live_room = MagicBean::LiveRoom.find_by(id: live_room_id)
    if live_room
      ActionCable.server.broadcast(live_room.channel_name, data)
    end
  end
end
