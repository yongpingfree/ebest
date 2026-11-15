# frozen_string_literal: true

module BeansAdmin::API::Entities
  class DeliveryArea < ::CommonEntities::Model
    expose :suburb, documentation: { type: String, desc: "自提点区域" }
    expose :latitude, documentation: { type: Float, desc: "纬度" }
    expose :longitude, documentation: { type: Float, desc: "经度" }
    expose :postal_code, documentation: { type: String, desc: "邮编" }
    expose :au_suburb_id
    expose :delivery_time_id
    expose :delivery_time_name
    expose :same_day_delivery_time_id
    expose :same_day_delivery_time_name
  end
end
