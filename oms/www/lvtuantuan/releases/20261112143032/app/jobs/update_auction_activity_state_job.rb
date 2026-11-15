# frozen_string_literal: true

class UpdateAuctionActivityStateJob < ApplicationJob
  queue_as :default

  def perform(id, action)
    activity = MagicBean::Auction::Activity.find_by id: id

    return if activity.nil?

    if action == MagicBean::Auction::Activity::HAMMER_ACTION
      activity.hammer! if activity.may_hammer?
    else
      activity.send("#{action}!") if activity.send("may_#{action}?")
    end
  end
end
