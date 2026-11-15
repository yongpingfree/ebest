# frozen_string_literal: true

module BeansAdmin::API::Entities
  class ItemTagGroup < ::CommonEntities::Model
    translate_expose :name
    expose :item_tag_type_id
    expose :item_tag_type_name
  end
end
