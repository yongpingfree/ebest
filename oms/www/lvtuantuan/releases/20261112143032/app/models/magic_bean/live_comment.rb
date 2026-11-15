module MagicBean
  class LiveComment < ApplicationRecord
    belongs_to :user
    belongs_to :live_room

    validates_presence_of :content
  end
end
