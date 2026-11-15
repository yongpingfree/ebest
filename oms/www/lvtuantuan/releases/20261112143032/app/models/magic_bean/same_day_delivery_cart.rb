# frozen_string_literal: true

class MagicBean::SameDayDeliveryCart < ApplicationRecord
  # scope

  # constants

  # attr related macros

  # association macros
  belongs_to :user
  has_many :same_day_delivery_cart_items, dependent: :destroy

  # validation macros

  # callbacks

  # other macros
end
