# frozen_string_literal: true

module CommonEntities
  class GooglePlacesDetail < Grape::Entity
    expose :city, :country, :place_id, :postal_code, :street, :street_number
    expose :lat, as: :latitude
    expose :lng, as: :longitude
    expose :name, as: :address

    expose :region_short_name, as: :region

    def region_short_name
      MagicBean::Address::REGION_NAME_HASH[object.region]
    end
  end
end
