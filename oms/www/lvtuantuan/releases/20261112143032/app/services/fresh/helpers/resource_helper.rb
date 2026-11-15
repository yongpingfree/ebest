# frozen_string_literal: true

module Fresh::Helpers
  module ResourceHelper
    include ::ApiHelpers::BaseResourceHelper

    @@fresh_api_logger = ::Logger.new("./log/fresh_api.log")

    def current_user
      MagicBean::AdminUser.first
    end

    def record_fresh_log
      @@fresh_api_logger.info("url: #{request.env["REQUEST_URI"]}; params: #{params}")
    end

    def entity_namespace_name
      "Fresh::API::Entities"
    end
  end
end
