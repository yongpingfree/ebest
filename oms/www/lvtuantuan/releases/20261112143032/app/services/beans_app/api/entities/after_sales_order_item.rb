# frozen_string_literal: true

module BeansApp::API::Entities
  class AfterSalesOrderItem < ::CommonEntities::Model
    expose :quantity
    expose :order_item, using: BeansApp::API::Entities::SimpleOrderItem
    expose :real_amount_in_cent
    expose :real_amount_in_yuan
  end
end
