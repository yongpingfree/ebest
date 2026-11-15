# frozen_string_literal: true
module BeansAdmin::API::Entities
  class Groupon < ::CommonEntities::Model
    expose :status
    expose :created_at
    expose :finished_at
    expose :cancel_at
    expose :creator, with: BeansAdmin::API::Entities::User
    expose :groupon_orders, with: BeansAdmin::API::Entities::SimpleOrder
  end
end
