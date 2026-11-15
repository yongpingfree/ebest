# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleGrouponOrder < Order
    expose :groupon_status
    expose :can_finish_order?, as: :can_finish_order
  end
end
