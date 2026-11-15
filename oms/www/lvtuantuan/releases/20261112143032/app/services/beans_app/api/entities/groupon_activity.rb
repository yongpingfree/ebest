# frozen_string_literal: true

module BeansApp::API::Entities
  class GrouponActivity < Grape::Entity
    expose :id
    expose :type
    expose :wms_sync_type
    expose :kind
    expose :price_range
    expose :min_price
    expose :user_count
    expose :waiting_groupons_count
    expose :finished_groupons_count
    expose :total_groupons_count
    expose :start_at
    expose :end_at
    expose :is_real
    expose :expired_hours
    expose :rules
    expose :fist_two_waiting_groupons, using: BeansApp::API::Entities::SimpleGroupon do |instance, _|
      if instance.is_a? MagicBean::BigGrouponActivity
        instance.groupons.not_closed.first(2)
      else
        instance.waiting_groupons.first(2)
      end
    end

    def total_groupons_count
      object.groupons.size
    end
  end
end
