# frozen_string_literal: true

module BeansAdmin::API::Entities
  class GiftActivity < ::CommonEntities::Model
    expose :start_at
    expose :end_at
    expose :status
    expose :rules
    expose :human_rules
  end
end
