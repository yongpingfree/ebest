# frozen_string_literal: true

module MagicBean
  class ItemNutritionValue < ApplicationRecord
    include ItemNutritionValuesImportConcern
    # scope

    # constants

    # attr related macros

    # association macros
    belongs_to :item
    belongs_to :nutrition

    # validation macros

    # callbacks

    # other macros
    delegate :name, to: :nutrition, prefix: true

    # class methods

    # instance methods
  end
end
