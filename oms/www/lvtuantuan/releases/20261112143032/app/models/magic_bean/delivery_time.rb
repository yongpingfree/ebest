# frozen_string_literal: true
module MagicBean
  class DeliveryTime < ApplicationRecord
    # concerns
    include WeekdaysConcern

    # scope

    # constants

    # attr related macros

    # association macros
    has_many :delivery_areas
    has_many :delivery_time_periods, dependent: :destroy
    has_many :delivery_time_period_settings

    # validation macros
    validates :name, presence: true

    # callbacks
    before_destroy :reset_delivery_areas

    # other macros
    accepts_nested_attributes_for :delivery_time_periods, allow_destroy: true

    # instance methods

    # class methods
    before_validation :set_specific_orders_limit_every_day

    def specific_orders_limit_active?
      !limited_by_orders_limit_every_day
    end

    # private methods
    private

    def set_specific_orders_limit_every_day
      if limited_by_orders_limit_every_day
        self.specific_orders_limit_every_day = 0
        self.specific_total_orders_limit_every_day = 0
      end
    end

    def reset_delivery_areas
      delivery_areas.update_all(delivery_time_id: nil)
    end
  end
end
