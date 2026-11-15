# frozen_string_literal: true

class MagicBean::AuSuburb < ApplicationRecord
  # concerns
  STATE_NAME_ABBR = {
    "ACT" => "Australian Capital Territory",
    "NSW" => "New South Wales",
    "NT" => "Northern Territory",
    "QLD" => "Queensland",
    "SA" => "South Australia",
    "TAS" => "Tasmania",
    "VIC" => "Victoria",
    "WA" => "Western Australia"
  }

  # scope

  # constants

  # attr related macros

  # association macros
  has_many :au_suburb_freight_templates, dependent: :restrict_with_error
  has_many :freight_templates, through: :au_suburb_freight_templates
  has_many :delivery_areas, dependent: :restrict_with_error

  belongs_to :store, optional: true

  ransacker :name_case_insensitive, type: :string do
    arel_table[:name].lower
  end

  # validation macros
  validates :name, presence: true
  validates :postal_code, presence: true, format: { with: /\A\d{4}\z/ }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_blank: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_blank: true
  validate :state_name_abbr_match

  # callbacks
  before_validation :strip_fields

  # other macros
  geocoded_by :address, latitude: :latitude, longitude: :longitude
  delegate :name, to: :store, prefix: true, allow_nil: true

  # instance methods

  # class methods

  # private methods

  private

  def strip_fields
    [:name, :postal_code, :state_name, :state_short_name].each do |field|
      self[field] = self[field].to_s.strip
    end
  end

  def state_name_abbr_match
    if state_name.blank?
      self.errors.add(:state_name, :empty)
      return
    end

    if state_short_name.blank?
      self.errors.add(:state_short_name, :empty)
      return
    end

    if STATE_NAME_ABBR[state_short_name] != state_name
      errors.add(:base, "州名与缩写不匹配")
    end
  end
end
