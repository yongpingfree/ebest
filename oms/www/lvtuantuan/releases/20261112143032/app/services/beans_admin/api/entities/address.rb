# frozen_string_literal: true

module BeansAdmin::API::Entities
  class Address < ::CommonEntities::Model
    expose :province_name
    expose :city_name
    expose :detail_info
    expose :tel_number
    expose :first_name
    expose :last_name
    expose :receiver_name
    expose :postal_code
    expose :is_default, documentation: { type: Grape::API::Boolean }
    expose :google_place_id
    expose :email
    expose :street
    expose :street_number
    expose :alias_name
    expose :unit_number
    expose :company_name
    expose :remark
  end
end
