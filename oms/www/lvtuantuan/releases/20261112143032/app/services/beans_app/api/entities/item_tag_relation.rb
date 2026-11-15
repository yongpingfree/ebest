# frozen_string_literal: true

module BeansApp::API::Entities
  class ItemTagRelation < ::CommonEntities::Model
    expose :item_tag_id
    expose :allow_view_same_tag_items
    expose :item_tag_name
    expose :item_tag_group_name
  end
end
