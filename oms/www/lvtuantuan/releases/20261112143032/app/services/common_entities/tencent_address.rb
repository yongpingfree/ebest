# frozen_string_literal: true

module CommonEntities
  class TencentAddress < Grape::Entity
    expose :address, :country, :province_name, :postal_code, :city_name, :detail_info, :street_number, :latitude, :longitude
  end
end
