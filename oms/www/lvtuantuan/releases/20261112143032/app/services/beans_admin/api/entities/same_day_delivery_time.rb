# frozen_string_literal: true
module BeansAdmin::API::Entities
  class SameDayDeliveryTime < SimpleSameDayDeliveryTime
    expose :same_day_delivery_time_periods, using: ::BeansAdmin::API::Entities::SameDayDeliveryTimePeriod
  end
end
