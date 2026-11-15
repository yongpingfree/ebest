# frozen_string_literal: true

module BeansApp::API::Entities
  class HomepagePagingSetting < ::CommonEntities::Model
    expose :name
    expose :image
    expose :selected_image
    expose :background_image
    expose :position
    expose :custom_page_en_name
    expose :show_banners
    expose :show_image_notice
    expose :banners
    expose :image_notice

    def custom_page_en_name
      object.custom_page.en_name
    end
  end
end
