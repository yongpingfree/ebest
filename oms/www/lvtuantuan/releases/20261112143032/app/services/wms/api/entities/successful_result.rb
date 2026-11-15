# frozen_string_literal: true

module Wms::API::Entities
  class SuccessfulResult < Grape::Entity
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
