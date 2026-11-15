# frozen_string_literal: true

module Wms::Helpers
  module ResourceHelper
    include ::ApiHelpers::BaseResourceHelper

    @@wms_api_logger = ::Logger.new("./log/wms_api.log")

    def current_user
      MagicBean::AdminUser.first
    end

    def record_wms_log
      @@wms_api_logger.info("url: #{request.env["REQUEST_URI"]}; params: #{params}")
    end

    def entity_namespace_name
      "Wms::API::Entities"
    end
  end
end
