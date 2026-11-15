# frozen_string_literal: true
module MagicBean
  class ShortenedScene < ApplicationRecord
    UNIQUE_KEY_LENGTH = 4

    before_create :generate_short_scene

    def generate_short_scene
      loop do
        self.short_scene = SecureRandom.hex(UNIQUE_KEY_LENGTH)
        break unless self.class.exists?(short_scene: short_scene)
      end
    end
  end
end
