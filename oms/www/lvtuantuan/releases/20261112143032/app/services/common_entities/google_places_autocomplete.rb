# frozen_string_literal: true

module CommonEntities
  class GooglePlacesAutocomplete < Grape::Entity
    expose :place_id
    expose :description, as: :address
  end
end
