# frozen_string_literal: true
module MagicBean
  class WebItem < ApplicationRecord
    # scope

    # constants

    # attr related macros

    # association macros
    belongs_to :item

    # validation macros

    # callbacks

    # other macros
    def has_video?
      video.dig("src").present?
    end
  end
end
