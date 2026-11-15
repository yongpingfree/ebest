# frozen_string_literal: true

module MagicBean
  class SameDayDeliveryTime < ApplicationRecord
    # concerns

    # scope

    # constants
    DEFAULT_TIME_PERIOD = ["14:00-16:00", "19:00-21:00"]

    # attr related macros

    # association macros
    has_many :delivery_areas
    has_many :same_day_delivery_time_periods, dependent: :destroy

    # validation macros
    validates :name, :same_day_delivery_time_periods, presence: true

    # callbacks
    before_destroy :reset_delivery_areas

    # other macros
    accepts_nested_attributes_for :same_day_delivery_time_periods, allow_destroy: true

    # instance methods

    # class methods

    def orders_limit_active?
      !limited_by_orders_limit_every_day
    end

    # private methods
    private
    def reset_delivery_areas
      delivery_areas.update_all(same_day_delivery_time_id: nil)
    end
  end
end
