# frozen_string_literal: true

module BeansApp::API::Entities
  class AuSuburb < SimpleAuSuburb
    expose :store, using: BeansApp::API::Entities::Store
  end
end
