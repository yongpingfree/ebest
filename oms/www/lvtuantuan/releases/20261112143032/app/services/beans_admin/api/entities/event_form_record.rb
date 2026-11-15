# frozen_string_literal: true

module BeansAdmin::API::Entities
  class EventFormRecord < ::CommonEntities::Model
    expose :user_id
    expose :user_member_mobile
    expose :user_member_id
    expose :user_nickname
    expose :data
    expose :completed_at

    def data
      object.data.to_json
    end
  end
end
