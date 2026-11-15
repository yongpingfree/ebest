# frozen_string_literal: true

module BeansAdmin::API::Entities
  class AfterSalesOrderItem < ::CommonEntities::Model
    expose :order_item, with: BeansAdmin::API::Entities::OrderItem
    expose :quantity
    expose :real_amount_in_cent
    expose :real_amount_in_yuan
    expose :cash_amount_in_cent
    expose :cash_amount_in_yuan
    expose :service_amount_in_cent
    expose :service_amount_in_yuan
    expose :cost_integral
    expose :gift_card_amount_in_cent
    expose :gift_card_amount_in_yuan
    expose :after_sale_id
    expose :ae_gst_amount_in_cent
    expose :ae_gst_amount_in_yuan
  end
end
