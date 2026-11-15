# frozen_string_literal: true

module BeansAdmin::API::Entities
  class MinePageActivitySetting < SimpleMinePageActivitySetting
    expose :custom_page, using: ::BeansAdmin::API::Entities::SimpleCustomPage
  end
end
