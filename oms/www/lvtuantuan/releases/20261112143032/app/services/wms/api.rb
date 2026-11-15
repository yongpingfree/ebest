# frozen_string_literal: true

require "grape-swagger"

# doc url: /wms/api/doc
module Wms
  class API < ::API
    helpers ::Wms::Helpers::ResourceHelper
    helpers ::Wms::Helpers::AuthenticationHelper
    helpers ::ApiHelpers::SharedParamsHelper

    mount API::V1
  end
end
