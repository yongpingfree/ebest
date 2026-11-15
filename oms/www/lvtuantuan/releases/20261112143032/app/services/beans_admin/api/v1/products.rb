# frozen_string_literal: true
module BeansAdmin
  class API::V1::Products < ::API

    namespace :products, desc: "Products API" do

      helpers do
        def includes
          [:brand, :category, :store]
        end
      end

      desc "Products list", {
        success: API::Entities::Product,
        is_array: true,
        skip_store_id_filter: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      route_param :id do
        desc "复制商品", {
          success: API::Entities::Item
        }
        get :copy do
          target = resource.item
          item = target.dup
          item.tag_list = target.tag_list
          item.sales_count = 0
          item.likes_count = 0
          item.comments_count = 0
          item.stock_keeping_units << target.stock_keeping_units.map do |v|
            v.dup.tap { |sku| sku.comments_count = 0 }
          end
          present item, with: API::Entities::Item
        end
      end
    end
  end
end
