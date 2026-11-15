# frozen_string_literal: true

module BeansApp
  class API::V2 < API
    prefix "api"
    version "v2"

    before do
      authenticate! if require_authentication?

      current_user.update(selected_store_id: current_store_id) if current_user && current_store_id&.positive? && current_user.selected_store_id != current_store_id
      Time.zone = current_store_time_zone
    end

    mount BeansApp::API::V2::Users
    mount BeansApp::API::V2::Wechats
    mount BeansApp::API::V2::Orders

    add_swagger_documentation info: {
      title: "APP API V2"
    }
  end
end
