# frozen_string_literal: true

module BeansApp::API::Entities
  class IntegralRecord < ::CommonEntities::Model
    expose :kind
    expose :status
    expose :description
    expose :integral
    expose :channel
  end
end
