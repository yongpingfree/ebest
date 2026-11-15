# frozen_string_literal: true
module BeansApp::API::Entities
  class Store < ::CommonEntities::Model
    expose :name
    expose :is_default
    expose :bg_color
    expose :default_au_suburb, using: ::BeansApp::API::Entities::SimpleAuSuburb
  end
end
