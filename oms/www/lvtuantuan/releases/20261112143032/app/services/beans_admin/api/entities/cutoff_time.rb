# frozen_string_literal: true

module BeansAdmin::API::Entities
  class CutoffTime < ::CommonEntities::Model
    expose :time_at
    expose :weekdays
    expose :deliver_after_n_days
  end
end
