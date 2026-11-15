# frozen_string_literal: true

module BeansApp::API::Entities
  class SimpleSkuInStockNotice < ::CommonEntities::Model
    expose :user_id
    expose :stock_keeping_unit_id
  end
end
