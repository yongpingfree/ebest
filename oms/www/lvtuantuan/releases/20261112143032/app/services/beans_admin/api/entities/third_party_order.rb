# frozen_string_literal: true

module BeansAdmin::API::Entities
  class ThirdPartyOrder < ::CommonEntities::Model
    expose :no
    expose :store_name
    expose :warehouse_order_id
    expose :warehouse_order_no
    expose :third_party_type
    expose :third_party_id
    expose :financial_status
    expose :fulfillment_status
    expose :delivery_type
    expose :sync_status
    expose :synced_at
    expose :delivery_date
    expose :prefer_time
    expose :order_total
    expose :total_discounts
    expose :total_line_items_price
    expose :payment_details
    expose :receiver_properties
    expose :buyer_message
    expose :refunded_amount
    expose :delivery_path
    expose :delivery_track
    expose :order_items
    expose :human_receiver_properties
    expose :freight_amount
    expose :can_return_inventory?, as: :can_return_inventory
    expose :can_create_warehouse_order?, as: :can_create_warehouse_order
  end
end
