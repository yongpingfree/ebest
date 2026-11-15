# frozen_string_literal: true
module BeansAdmin::API::Entities
  class DeliveryTime < SimpleDeliveryTime
    expose :delivery_time_periods, using: ::BeansAdmin::API::Entities::DeliveryTimePeriod
  end
end
