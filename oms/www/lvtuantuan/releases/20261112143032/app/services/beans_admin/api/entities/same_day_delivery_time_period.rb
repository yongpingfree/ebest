# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SameDayDeliveryTimePeriod < ::CommonEntities::Model
    expose :time_period
    expose :kind
    expose :time_window
    expose :address_count_limit
    expose :enabled
    expose :free_shipping_amount_in_cent
    expose :free_shipping_amount_in_yuan
    expose :extra_shipping_amount_in_cent
    expose :extra_shipping_amount_in_yuan
  end
end
