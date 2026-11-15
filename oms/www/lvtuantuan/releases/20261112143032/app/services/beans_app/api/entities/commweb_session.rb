# frozen_string_literal: true

module BeansApp::API::Entities
  class CommwebSession < Grape::Entity
    expose :session_id
    expose :status
    expose :api_version
    expose :merchant_id

    def session
      object["session"]
    end

    def session_id
      session["id"]
    end

    def status
      session["updateStatus"]
    end

    def api_version
      Commweb::Payment::API_VERSION
    end

    def merchant_id
      Commweb::Payment::APP_MERCHANT_ID
    end
  end
end
