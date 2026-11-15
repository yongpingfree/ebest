# frozen_string_literal: true
module BeansAdmin::API::Entities
  class SimpleDeliveryTime < ::CommonEntities::Model
    expose :name
    expose :limited_by_orders_limit_every_day
    expose :weekdays
    expose :delivery_area_ids
    expose :delivery_areas
  end
end
