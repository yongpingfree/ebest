# frozen_string_literal: true
module MagicBean
  class LiveRoomViewedUserStat < ApplicationRecord
    belongs_to :live_room

    validates :count, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :time_str, presence: true

    def self.real_time_chart_data(live_room_id)
      hash = {}
      MagicBean::LiveRoomViewedUserStat.where(live_room_id: live_room_id).order(created_at: :asc).find_each do |record|
        hash[record.time_str] = record.count
      end

      hash
    end
  end
end
