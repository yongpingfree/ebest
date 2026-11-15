# frozen_string_literal: true

module BeansAdmin::API::Entities
  class MultiLangConfig < ::CommonEntities::Model
    translate_expose :value
    expose :store_id
    expose :store_name
    expose :name
    expose :key
    expose :hint
  end
end
