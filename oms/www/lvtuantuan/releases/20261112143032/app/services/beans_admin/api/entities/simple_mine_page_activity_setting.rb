# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleMinePageActivitySetting < ::CommonEntities::Model
    translate_expose :name
    expose :icon
    expose :position
    expose :enabled
    expose :custom_page_id
    expose :path
    expose :path_name
  end
end
