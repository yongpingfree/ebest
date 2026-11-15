# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleHomepagePagingSetting < ::CommonEntities::Model
    expose :name
    expose :image
    expose :selected_image
    expose :background_image
    expose :position
    expose :custom_page_id
    expose :show_banners
    expose :show_image_notice
  end
end
