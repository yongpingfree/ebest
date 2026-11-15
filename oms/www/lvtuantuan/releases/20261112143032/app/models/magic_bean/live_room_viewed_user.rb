# frozen_string_literal: true

module MagicBean
  class LiveRoomViewedUser < ApplicationRecord
    belongs_to :live_room
    belongs_to :user

    delegate :nickname, to: :user, prefix: true

    validates :user_id, uniqueness: { scope: :live_room_id }
  end
end
