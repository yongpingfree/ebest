# frozen_string_literal: true

module MagicBean
  class HotSearch < ApplicationRecord
    # constants

    # concerns

    # attr related macros

    # association macros
    belongs_to :store, optional: true

    # validation macros
    validates :word, presence: true
    validates :position, presence: true, numericality: { only_integer: true }

    # callbacks

    # other macros
    translates :word
    globalize_accessors attributes: [:word]

    delegate :name, to: :store, prefix: true, allow_nil: true

    # scopes
    scope :show, -> { where(show: true) }
    scope :of_channel, ->(channel) { where("channels @> ?", [channel].to_json) }

    # class methods

    # instance methods
  end
end
