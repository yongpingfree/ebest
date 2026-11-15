# frozen_string_literal: true

module BeansAdmin::API::Entities
  class WarehouseOrder < ::CommonEntities::Model
    expose :no
    expose :buyer_message
    expose :remark
    expose :sync_status
    expose :channel
    expose :human_receiver_properties
    expose :authority_to_leave
    expose :deliver_to_door
    expose :delivery_type
    expose :delivery_date
    expose :prefer_time
    expose :delivery_track
    expose :store_name
    expose :express_carrier
    expose :user, using: BeansAdmin::API::Entities::SimpleUser
    expose :orders, using: BeansAdmin::API::Entities::WarehouseSubOrder
    expose :shopline_orders, using: BeansAdmin::API::Entities::ThirdPartyOrder
  end
end
