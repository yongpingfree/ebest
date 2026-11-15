# frozen_string_literal: true

module BeansApp::API::Entities
  class SimpleShoppingCartItem < ::CommonEntities::Model
    expose :quantity
    expose :stock_keeping_unit, using: BeansApp::API::Entities::SimpleStockKeepingUnit
  end
end
