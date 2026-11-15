# frozen_string_literal: true

module BeansAdmin::API::Entities
  class AeDropShipperOrder < ::CommonEntities::Model
    expose :ae_order_no
    expose :order_paidtime
    expose :gmt_create
    expose :order_status
    expose :logistics_status
    expose :order_amount
    expose :child_order_list
    expose :store_info
  end
end
