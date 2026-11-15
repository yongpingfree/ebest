# frozen_string_literal: true

module BeansApp::API::Entities
  class LiveRoomSku < ::CommonEntities::Model
    expose :stock_keeping_unit, using: BeansApp::API::Entities::SimpleStockKeepingUnit
  end
end
