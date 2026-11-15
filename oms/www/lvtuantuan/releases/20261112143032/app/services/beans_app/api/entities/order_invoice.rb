# frozen_string_literal: true

module BeansApp::API::Entities
  class OrderInvoice < ::CommonEntities::Model
    expose :no
    expose :state
    expose :order_id
  end
end
