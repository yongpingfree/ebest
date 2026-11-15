# frozen_string_literal: true

module BeansApp::API::Entities
  class DeliveryArea < ::CommonEntities::Model
    expose :au_suburb_id, documentation: { type: Integer }
    expose :latitude, documentation: { type: Float, desc: "纬度" }
    expose :longitude, documentation: { type: Float, desc: "经度" }
    expose :postal_code, documentation: { type: String, desc: "邮编" }
    expose :suburb, documentation: { type: String, desc: "区域" }
  end
end
