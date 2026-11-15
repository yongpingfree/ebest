# frozen_string_literal: true

module BeansAdmin::API::Entities
  class AeCategory < ::CommonEntities::Model
    expose :name
    expose :ae_id
  end
end
