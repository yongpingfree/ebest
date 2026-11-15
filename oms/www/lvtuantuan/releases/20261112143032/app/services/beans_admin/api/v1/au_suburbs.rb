# frozen_string_literal: true

module BeansAdmin
  class API::V1::AuSuburbs < ::API

    namespace :au_suburbs, desc: "SUBURBS API" do
      helpers do
        def permitted_params
          [:name, :postal_code, :state_name, :state_short_name, :latitude, :longitude, :store_id]
        end

        def includes
          [:store]
        end
      end

      desc "suburbs", {
        success: API::Entities::AuSuburb,
        is_array: true,
        skip_store_id_filter: true
      }
      paginate
      params do
        optional :keyword, as: :name_or_postal_code_cont, type: String, desc: "关键字"
      end
      get do
        response_collection
      end

      desc "新增Suburb", {
        success: API::Entities::AuSuburb,
        skip_store_id: true
      }
      params do
        requires :name, type: String, desc: "区名"
        requires :state_name, type: String, desc: "州名"
        requires :state_short_name, type: String, desc: "州名缩写"
        optional :latitude, type: Float, desc: "纬度"
        optional :longitude, type: Float, desc: "经度"
        optional :store_id, type: Integer, desc: "门店ID"
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "Suburb详情", {
          success: API::Entities::AuSuburb
        }
        get do
          authorize_and_response_resource
        end

        desc "更新Suburb", {
          success: API::Entities::AuSuburb,
          skip_store_id: true
        }
        params do
          requires :name, type: String, desc: "区名"
          requires :state_name, type: String, desc: "州名"
          requires :state_short_name, type: String, desc: "州名缩写"
          optional :latitude, type: Float, desc: "纬度"
          optional :longitude, type: Float, desc: "经度"
          optional :store_id, type: Integer, desc: "门店ID"
        end
        put do
          authorize_and_update_resource
        end

        desc "删除Suburb", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
