# frozen_string_literal: true

class MagicBean::DeliveryTimePeriod < ApplicationRecord
  # scope

  # constants

  # attr related macros
  translates :title
  globalize_accessors attributes: [:title]

  # association macros
  belongs_to :delivery_time
  has_many :delivery_time_period_settings, dependent: :destroy

  # validation macros

  # callbacks

  # other macros
  accepts_nested_attributes_for :delivery_time_period_settings, allow_destroy: true
end
