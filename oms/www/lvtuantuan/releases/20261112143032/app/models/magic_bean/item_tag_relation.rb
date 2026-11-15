# frozen_string_literal: true

module MagicBean
  class ItemTagRelation < ApplicationRecord
    belongs_to :item
    belongs_to :item_tag, counter_cache: true

    validates :item_id, uniqueness: { scope: :item_tag_id }

    delegate :name, to: :item_tag, prefix: true
    delegate :item_tag_group_name, to: :item_tag
  end
end
