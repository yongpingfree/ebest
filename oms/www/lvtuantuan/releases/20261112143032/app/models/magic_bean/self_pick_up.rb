# frozen_string_literal: true

class MagicBean::SelfPickUp < ApplicationRecord
  # concerns
  include WeekdaysConcern

  # scope
  scope :active, -> { where(enabled: true) }

  # constants
  TIME_PERIOD = ["9:00-17:00", "9:00-21:00", "17:00-21:00", "21:00-23:00"]
  EMAIL_PATTERN = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i

  # attr related macros

  # association macros
  belongs_to :store
  has_many :orders, dependent: :restrict_with_error

  ransacker :city_name_case_insensitive, type: :string do
    arel_table[:city_name].lower
  end

  # validation macros
  validates_presence_of :name, :mobile, :opening_hours, :address, :postal_code, :province_name, :city_name, :google_place_id, :latitude, :longitude
  validates :email, format: { with: EMAIL_PATTERN }, if: -> { email.present? }
  validates :time_period, presence: true

  # callbacks
  before_save :format_time_period, if: :time_period_changed?

  # other macros
  geocoded_by :address, latitude: :latitude, longitude: :longitude

  def full_address
    "#{address}, #{city_name}, #{postal_code}(Tel: #{mobile})"
  end

  def to_order_json(receiver_first_name, receiver_last_name, receiver_tel_number)
    {
      id: id,
      province_name: province_name,
      city_name: city_name,
      detail_info: "#{address}(Tel: #{mobile})",
      tel_number: receiver_tel_number,
      first_name: receiver_first_name,
      last_name: receiver_last_name,
      postal_code: postal_code,
      street_number: street_number,
      street: street,
      type: "SelfPickUp"
    }.as_json
  end

  # 去除所有空格
  def format_time_period
    time_period.map! do |period|
      period.gsub(/\s+/, "")
    end
  end
end
