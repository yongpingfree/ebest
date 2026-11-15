# frozen_string_literal: true

require "grape-swagger"

# doc url: /admin/api/doc
module BeansAdmin
  class API < ::API
    use Rack::Session::Cookie,
        secret: Rails.application.credentials.dig(Rails.env.to_sym, :jwt_secret),
        expire_after: ApplicationRecord::ADMIN_LOGIN_SECOND # one day in second

    helpers ::BeansAdmin::Helpers::SessionHelper
    helpers ::BeansAdmin::Helpers::ResourceHelper
    helpers ::BeansAdmin::Helpers::ExportHelper
    helpers ::BeansAdmin::Helpers::ItemsHelper

    mount API::V1
  end
end
