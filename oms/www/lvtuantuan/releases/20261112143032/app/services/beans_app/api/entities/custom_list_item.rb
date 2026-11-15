# frozen_string_literal: true

module BeansApp::API::Entities
  class CustomListItem < Grape::Entity
    expose :item, merge: true, using: ::BeansApp::API::Entities::MinimalItem
  end
end
