# frozen_string_literal: true

class SendLiveStartNotificationJob < ApplicationJob
  queue_as :default

  def perform(live_room_id)
    live_room = MagicBean::LiveRoom.find_by(id: live_room_id)
    if live_room.present?
      live_room.send_live_start_notification_to_subscripters
    end
  end
end
