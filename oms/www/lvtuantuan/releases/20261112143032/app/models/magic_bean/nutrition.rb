# frozen_string_literal: true

module MagicBean
  class Nutrition < ApplicationRecord
    # scope

    # constants

    # attr related macros
    translates :name
    globalize_accessors attributes: [:name]

    # association macros
    has_many :item_nutrition_values, dependent: :restrict_with_error

    # validation macros
    validates :slug, presence: true, uniqueness: true

    # callbacks

    # other macros

    # class methods

    # instance methods
  end
end
