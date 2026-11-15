# frozen_string_literal: true

module BeansApp::API::Entities
  class Page < Grape::Entity
    expose :id, documentation: { type: Integer }
    expose :name
    expose :content
    expose :created_at
    expose :updated_at
  end
end
