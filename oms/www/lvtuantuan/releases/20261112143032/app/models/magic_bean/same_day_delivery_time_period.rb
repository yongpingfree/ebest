# frozen_string_literal: true

module MagicBean
  class SameDayDeliveryTimePeriod < ApplicationRecord
    include PriceConvertConcern

    # attr related macros
    enum kind: {
      daytime: 1,
      nighttime: 2
    }

    enum time_window: {
      one_hour: 1,
      two_hours: 2,
      three_hours: 3,
      four_hours: 4,
      five_hours: 5,
      six_hour: 6,
      seven_hour: 7,
      eight_hour: 8,
    }

    convert_price_to_yuan :extra_shipping_amount_in_cent, :free_shipping_amount_in_cent

    # association macros
    belongs_to :same_day_delivery_time

    # validation macros
    validates :kind, :time_period, :time_window, presence: true
    validates :extra_shipping_amount_in_cent, :free_shipping_amount_in_cent, :address_count_limit, presence: true, numericality: { greater_than_or_equal_to: 0 }
  end
end
