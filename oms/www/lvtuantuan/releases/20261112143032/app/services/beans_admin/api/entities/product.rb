# frozen_string_literal: true
module BeansAdmin::API::Entities
  class Product < ::CommonEntities::Model
    expose :title
    expose :sub_title
    expose :description
    expose :shared_description
    expose :cover
    expose :share_cover
    expose :main_images
    expose :detail_video
    expose :detail_images
    expose :actual_monthly_sales_count
    expose :category_id
    expose :minor_category_id
    expose :brand_id
    expose :store_id
    expose :monthly_sales_count_offset
    expose :sales_count_offset
    expose :qa_and_guarantee_id
    expose :category_name
    expose :minor_category_name
    expose :brand_name
    expose :store_name
  end
end
