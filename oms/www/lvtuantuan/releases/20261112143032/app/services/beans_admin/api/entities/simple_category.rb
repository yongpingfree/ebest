# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleCategory < ::CommonEntities::Model
    translate_expose :name
    expose :status, :position, :item_position, :icon, :bg_color, :display_length, :filter_icon
    expose :can_create_invoice
    expose :need_age_verification
    expose :parent_id, documentation: { type: Integer }
    expose :show_on_web
    expose :goto_kind
    expose :search_keywords
    expose :external_url
  end
end
