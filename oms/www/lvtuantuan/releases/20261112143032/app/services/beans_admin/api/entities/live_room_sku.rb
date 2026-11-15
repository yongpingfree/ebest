# frozen_string_literal: true
module BeansAdmin::API::Entities
  class LiveRoomSku < ::CommonEntities::Model
    expose :stock_keeping_unit_id
    expose :stock_keeping_unit_human_title
  end
end
