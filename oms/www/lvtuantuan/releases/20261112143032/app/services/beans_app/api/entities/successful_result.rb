# frozen_string_literal: true

module BeansApp::API::Entities
  class SuccessfulResult < ::CommonEntities::Model
    expose :code
    expose :message

    private

    def code
      200
    end

    def message
      "OK"
    end
  end
end
