# frozen_string_literal: true

class MagicBean::DeliveryTimePeriodSetting < ApplicationRecord
  include PriceConvertConcern

  # scope

  # constants

  # attr related macros
  convert_price_to_yuan :freight_in_cent

  # association macros
  belongs_to :delivery_time_period
  belongs_to :delivery_time, optional: true

  # validation macros
  validates :prefer_time, presence: true

  # callbacks

  # other macros

  # instance methods

  # class methods
  before_save :set_delivery_time_id

  # private methods
  private

  def set_delivery_time_id
    self.delivery_time_id = delivery_time_period.delivery_time_id
  end
end
