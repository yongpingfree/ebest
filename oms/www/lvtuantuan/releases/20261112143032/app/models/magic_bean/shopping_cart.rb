# frozen_string_literal: true
module MagicBean
  class ShoppingCart < ApplicationRecord
    # scope

    # constants

    # attr related macros

    # association macros
    belongs_to :user
    has_many :shopping_cart_items, dependent: :destroy

    # validation macros

    # callbacks

    # other macros
  end
end
