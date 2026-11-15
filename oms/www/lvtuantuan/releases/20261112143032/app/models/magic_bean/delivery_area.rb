# frozen_string_literal: true

class MagicBean::DeliveryArea < ApplicationRecord

  # scope

  # constants

  # attr related macros
  delegate :name, to: :delivery_time, allow_nil: true, prefix: true
  delegate :name, to: :same_day_delivery_time, allow_nil: true, prefix: true

  ransacker :suburb_case_insensitive, type: :string do
    arel_table[:suburb].lower
  end

  # association macros
  belongs_to :delivery_time, optional: true
  belongs_to :same_day_delivery_time, optional: true
  belongs_to :au_suburb

  # validation macros
  validates :suburb, presence: true
  validates_uniqueness_of :suburb, scope: :postal_code
  validates_presence_of :postal_code

  # callbacks

  # other macros
  geocoded_by :address, latitude: :latitude, longitude: :longitude
end
