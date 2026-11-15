# frozen_string_literal: true
module BeansAdmin::API::Entities
  class SimplePagePopup < ::CommonEntities::Model
    expose :title
    expose :image
    expose :for_new_user
    expose :start_at
    expose :end_at
    expose :position
    expose :is_always
    expose :is_fullscreen
    expose :page_type
    expose :locales
  end
end
