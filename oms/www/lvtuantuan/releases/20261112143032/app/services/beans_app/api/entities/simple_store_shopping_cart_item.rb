# frozen_string_literal: true

module BeansApp::API::Entities
  class SimpleStoreShoppingCartItem < ::Grape::Entity
    expose :store, using: BeansApp::API::Entities::Store
    expose :shopping_cart_items, using: BeansApp::API::Entities::SimpleShoppingCartItem
  end
end
