# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleOrderInvoice < ::CommonEntities::Model
    expose :no
    expose :state
    expose :order_id
    expose :invoice_properties
  end
end
