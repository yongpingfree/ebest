# frozen_string_literal: true

module BeansAdmin::API::Entities
  class TopLeftItemTag < ::CommonEntities::Model
    expose :name
    expose :icon
    expose :start_at
    expose :end_at
    expose :store_id
    expose :store_name
    expose :item_ids
  end
end
