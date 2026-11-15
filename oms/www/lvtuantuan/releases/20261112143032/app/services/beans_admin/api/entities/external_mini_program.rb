# frozen_string_literal: true

module BeansAdmin::API::Entities
  class ExternalMiniProgram < ::CommonEntities::Model
    expose :name
    expose :origin_id
    expose :app_id
    expose :path
    expose :env_version
  end
end
