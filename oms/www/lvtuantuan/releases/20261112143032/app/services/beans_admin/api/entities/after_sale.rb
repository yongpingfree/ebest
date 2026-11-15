# frozen_string_literal: true

module BeansAdmin::API::Entities
  class AfterSale < SimpleAfterSale
    expose :agreed_at
    expose :images
    expose :seller_reply
    expose :order_human_receiver_properties
    expose :order_human_gifts_properties
    expose :order_human_pool_gifts_properties
  end
end
