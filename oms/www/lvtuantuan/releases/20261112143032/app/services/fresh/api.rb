# frozen_string_literal: true

require "grape-swagger"

# doc url: /fresh/api/doc
module Fresh
  class API < ::API
    helpers ::Fresh::Helpers::ResourceHelper
    helpers ::Fresh::Helpers::AuthenticationHelper
    helpers ::ApiHelpers::SharedParamsHelper

    mount API::V1
  end
end
