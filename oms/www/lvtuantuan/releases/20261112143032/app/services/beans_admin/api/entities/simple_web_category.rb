# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleWebCategory < ::CommonEntities::Model
    translate_expose :name
    expose :status, :position, :icon, :bg_color, :display_length, :filter_icon
    expose :can_create_invoice
    expose :need_age_verification
    expose :parent_id, documentation: { type: Integer }
    expose :search_keywords
  end
end
