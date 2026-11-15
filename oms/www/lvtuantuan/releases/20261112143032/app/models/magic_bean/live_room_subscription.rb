# frozen_string_literal: true

module MagicBean
  class LiveRoomSubscription < ApplicationRecord
    # constants

    # concerns

    # attr related macros

    # association macros
    belongs_to :live_room, counter_cache: true
    belongs_to :user

    # validation macros
    validates :live_room_id, uniqueness: { scope: :user_id }

    # callbacks

    # other macros

    # scopes

    # class methods

    # instance methods
  end
end
