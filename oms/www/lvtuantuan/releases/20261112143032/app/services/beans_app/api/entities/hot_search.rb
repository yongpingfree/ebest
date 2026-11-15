# frozen_string_literal: true

module BeansApp::API::Entities
  class HotSearch < ::CommonEntities::Model
    expose :word
    expose :position
  end
end
