# frozen_string_literal: true

require "grape-swagger"

# doc url: /app/api/doc
module BeansApp
  class API < ::API
    use ActionDispatch::Session::CookieStore, expire_after: 10.years

    helpers ::ApiHelpers::AuthenticationHelper
    helpers ::ApiHelpers::HistoryHelper
    helpers ::BeansApp::Helpers::ResourceHelper

    after do
      # save_history
    end

    mount API::V1
    mount API::V2
  end
end
