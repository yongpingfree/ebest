# frozen_string_literal: true

module BeansAdmin::API::Entities
  class ItemTag < ::CommonEntities::Model
    translate_expose :name
    expose :item_tag_group_id
    expose :item_tag_group_name
    expose :item_tag_type_name
  end
end
