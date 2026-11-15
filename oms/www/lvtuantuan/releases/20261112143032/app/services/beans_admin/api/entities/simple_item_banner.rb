# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleItemBanner < ::CommonEntities::Model
    expose :title, :banner, :start_at, :end_at, :enabled, :item_ids, :path, :path_name
  end
end
