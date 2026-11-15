# frozen_string_literal: true

module BeansAdmin::API::Entities
  class DeliveryTimePeriodSetting < ::CommonEntities::Model
    expose :prefer_time
    expose :order_address_limit_every_day
    expose :freight_in_cent
    expose :freight_in_yuan
  end
end
