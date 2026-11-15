# frozen_string_literal: true

module MagicBean
  class ItemTagType < ApplicationRecord
    # scope

    # constants

    # attr related macros

    # association macros
    has_many :item_tag_groups, dependent: :restrict_with_error

    # validation macros
    validates :name, presence: true

    # callback

    # other macros
  end
end
