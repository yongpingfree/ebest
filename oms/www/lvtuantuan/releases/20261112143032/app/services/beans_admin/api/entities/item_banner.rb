# frozen_string_literal: true

module BeansAdmin::API::Entities
  class ItemBanner < SimpleItemBanner
    expose :path_name
    expose :items, using: ::BeansAdmin::API::Entities::SimpleItem
  end
end
