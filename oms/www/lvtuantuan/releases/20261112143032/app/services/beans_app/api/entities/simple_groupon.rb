# frozen_string_literal: true

module BeansApp::API::Entities
  class SimpleGroupon < ::CommonEntities::Model
    expose :status
    expose :is_creator
    expose :is_joined
    expose :required_joined_count
    expose :current_time
    expose :expired_at
    expose :creator_groupon_order, as: :creator, using: BeansApp::API::Entities::GrouponOrder
    expose :joined_groupon_orders, as: :joined_users, using: BeansApp::API::Entities::GrouponOrder
    expose :current_user_groupon_order, using: BeansApp::API::Entities::SimpleOrder

    # 团长不显示 “参团”
    def is_creator
      object.creator_id == current_user&.id
    end

    def current_user_groupon_order
      object.groupon_orders.find_by(user_id: current_user&.id)
    end

    def is_joined
      object.users.ids.include?(current_user&.id)
    end

    def current_time
      Time.current
    end
  end
end
