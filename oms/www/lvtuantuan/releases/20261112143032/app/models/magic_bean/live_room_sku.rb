module MagicBean
  class LiveRoomSku < ApplicationRecord
    belongs_to :live_room
    belongs_to :stock_keeping_unit

    delegate :human_title, to: :stock_keeping_unit, prefix: true
  end
end
