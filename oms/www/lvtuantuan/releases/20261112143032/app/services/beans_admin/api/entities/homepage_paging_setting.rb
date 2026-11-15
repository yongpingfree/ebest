# frozen_string_literal: true

module BeansAdmin::API::Entities
  class HomepagePagingSetting < SimpleHomepagePagingSetting
    expose :custom_page, using: ::BeansAdmin::API::Entities::SimpleCustomPage
    expose :banners
    expose :image_notice
  end
end
