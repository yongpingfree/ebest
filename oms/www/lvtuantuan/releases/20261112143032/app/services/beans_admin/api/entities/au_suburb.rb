# frozen_string_literal: true

module BeansAdmin::API::Entities
  class AuSuburb < Grape::Entity
    expose :id
    expose :name
    expose :state_name
    expose :state_short_name
    expose :postal_code
    expose :latitude
    expose :longitude
    expose :store_id
    expose :store_name
  end
end
