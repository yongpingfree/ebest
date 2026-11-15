# frozen_string_literal: true

module BeansAdmin::API::Entities
  class DeliveryTimePeriod < ::CommonEntities::Model
    translate_expose :title
    expose :delivery_time_period_settings, using: ::BeansAdmin::API::Entities::DeliveryTimePeriodSetting
  end
end 