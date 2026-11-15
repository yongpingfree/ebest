# frozen_string_literal: true

module BeansApp::Helpers
  module ResourceHelper
    include ::ApiHelpers::BaseResourceHelper

    def entity_namespace_name
      "BeansApp::API::Entities"
    end

    def session
      env["rack.session"]
    end
  end
end
