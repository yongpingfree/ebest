# frozen_string_literal: true

module BeansApp::API::Entities
  class AgeVerification < ::CommonEntities::Model
    expose :title
    expose :content
    expose :image
  end
end
