# frozen_string_literal: true
module BeansAdmin
  class API::V1::HotSearches < ::API
    namespace :hot_searches, desc: "HotSearches API" do
      helpers do
        def permitted_params
          resource_class.globalize_attribute_names + [:position, :store_id, :show, :ae_drop_shipper, channels: []]
        end

        def default_order
          "position asc"
        end

        def includes
          [:store, :translations]
        end
      end

      desc "HotSearches list", {
        success: API::Entities::HotSearch,
        is_array: true
      }
      paginate
      params do
        optional :ae_drop_shipper_eq, type: Boolean
      end
      get do
        authorize_and_response_collection
      end

      desc "Create hot_search", {
        success: API::Entities::HotSearch
      }
      params do
        requires :position, type: Integer, natural_number: true, desc: "位置"
        requires :channels, type: Array, desc: "平台"
        optional :show, type: Grape::API::Boolean, desc: "是否显示"
        optional :ae_drop_shipper, type: Boolean, default: false
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "HotSearch detail", {
          success: API::Entities::HotSearch
        }
        get do
          authorize_and_response_resource
        end

        desc "Update hot_search", {
          success: API::Entities::HotSearch,
          skip_store_id: true
        }
        params do
          optional :word, type: String, desc: "热词"
          optional :position, type: Integer, natural_number: true, desc: "位置"
          optional :channels, type: Array, desc: "平台"
          optional :show, type: String, desc: "是否显示"
        end
        put do
          authorize_and_update_resource
        end

        desc "Destroy hot_search", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
