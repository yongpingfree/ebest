# frozen_string_literal: true
module MagicBean
  class LiveRoomOrder < ApplicationRecord
    belongs_to :live_room
    belongs_to :order
    belongs_to :user
  end
end
