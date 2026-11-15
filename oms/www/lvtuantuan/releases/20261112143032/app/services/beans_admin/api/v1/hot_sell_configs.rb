# frozen_string_literal: true
module BeansAdmin
  class API::V1::HotSellConfigs < ::API
    namespace :hot_sell_configs, desc: "HotSells API" do
      helpers do
        def permitted_params
          [:last_x_days, :show_item_nums, :contains_order_gift, :contains_order_pool_gift, :is_show_storage_on_sale, :enabled, :category_id, :store_id, :position]
        end

        def default_order
          ["created_at DESC"]
        end

        def includes
          [:store, category: [:translations]]
        end
      end

      desc "热卖榜列表", {
        success: API::Entities::HotSellConfig,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "创建热卖榜", {
        success: API::Entities::HotSellConfig
      }
      params do
        requires :last_x_days, type: Integer, natural_number: true, desc: "过去X天销量"
        requires :show_item_nums, type: Integer, natural_number: true, desc: "最多展示几个商品"
        requires :contains_order_gift, type: Grape::API::Boolean, desc: "销量包含全场满赠数量"
        requires :contains_order_pool_gift, type: Grape::API::Boolean, desc: "销量包含优惠池满赠数量"
        requires :is_show_storage_on_sale, type: Grape::API::Boolean, desc: "仅展示有库存开卖商品"
        requires :enabled, type: Grape::API::Boolean, desc: "是否展示热卖榜"
        requires :category_id, type: Integer, desc: "分类id"
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "热卖榜详情", {
          success: API::Entities::HotSellConfig
        }
        get do
          authorize_and_response_resource
        end

        desc "更新热卖榜", {
          success: API::Entities::HotSellConfig
        }
        params do
          optional :last_x_days, type: Integer, natural_number: true, desc: "过去X天销量"
          optional :show_item_nums, type: Integer, natural_number: true, desc: "最多展示几个商品"
          optional :contains_order_gift, type: Grape::API::Boolean, desc: "销量包含全场满赠数量"
          optional :contains_order_pool_gift, type: Grape::API::Boolean, desc: "销量包含优惠池满赠数量"
          optional :is_show_storage_on_sale, type: Grape::API::Boolean, desc: "仅展示有库存开卖商品"
          optional :enabled, type: Grape::API::Boolean, desc: "是否展示热卖榜"
        end
        put do
          params.delete(:store_id)
          authorize_and_update_resource
        end

        desc "删除热卖榜", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
