# frozen_string_literal: true

module BeansApp::API::Entities
  class StoreSameDayDeliveryCartItem < ::Grape::Entity
    expose :store, using: BeansApp::API::Entities::Store
    expose :same_day_delivery_cart_items, using: BeansApp::API::Entities::SameDayDeliveryCartItem
  end
end
