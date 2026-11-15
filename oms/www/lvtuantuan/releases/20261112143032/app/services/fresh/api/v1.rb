# frozen_string_literal: true

module Fresh
  class API::V1 < API
    prefix "api"
    version "v1"

    before do
      authenticate!
      record_fresh_log
    end

    mount Fresh::API::V1::Users

    add_swagger_documentation info: {
      title: "Fresh API"
    }
  end
end
