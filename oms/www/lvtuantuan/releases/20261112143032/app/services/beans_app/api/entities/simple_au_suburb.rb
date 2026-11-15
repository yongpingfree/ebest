# frozen_string_literal: true

module BeansApp::API::Entities
  class SimpleAuSuburb < Grape::Entity
    expose :id
    expose :name
    expose :state_name
    expose :state_short_name
    expose :postal_code
    expose :latitude
    expose :longitude
  end
end
