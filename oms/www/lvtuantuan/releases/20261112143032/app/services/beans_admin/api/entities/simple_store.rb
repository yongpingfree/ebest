# frozen_string_literal: true
module BeansAdmin::API::Entities
  class SimpleStore < ::CommonEntities::Model
    expose :name
    expose :is_default
    expose :bg_color
    expose :short_name
  end
end
