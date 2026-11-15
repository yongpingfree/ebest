# frozen_string_literal: true
module BeansAdmin
  class API::V1::PagePopups < ::API

    namespace :page_popups, desc: "PagePopups API" do
      helpers do
        def permitted_params
          [:title, :image, :path, :for_new_user, :start_at, :end_at, :position, :store_id, :is_always, :is_fullscreen, :page_type, au_suburb_ids: [], locales: []]
        end

        def sort_by
          "position asc"
        end
      end

      desc "PagePopups list", {
        success: API::Entities::PagePopup,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "Create page_popup", {
        success: API::Entities::PagePopup
      }
      params do
        requires :title, type: String, desc: "title"
        requires :image, type: String, desc: "image"
        requires :start_at, type: String, desc: "开始时间"
        requires :end_at, type: String, desc: "结束时间"
        requires :position, type: Integer, natural_number: true, desc: "位置"
        optional :path, type: String, desc: "小程序路径"
        optional :for_new_user, type: Grape::API::Boolean, desc: "新用户可用"
        optional :is_always, type: String, desc: "是否总是弹出"
        optional :is_fullscreen, type: String, desc: "是否全屏"
        optional :locales, type: Array, desc: "用户语系"
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "PagePopup detail", {
          success: API::Entities::PagePopup
        }
        get do
          authorize_and_response_resource(present: { with: BeansAdmin::API::Entities::PagePopupDetail })
        end

        desc "Update page_popup", {
          success: API::Entities::PagePopup,
          skip_store_id: true
        }
        params do
          optional :title, type: String, desc: "title"
          optional :image, type: String, desc: "image"
          optional :start_at, type: String, desc: "开始时间"
          optional :end_at, type: String, desc: "结束时间"
          optional :position, type: Integer, natural_number: true, desc: "位置"
          optional :path, type: String, desc: "小程序路径"
          optional :for_new_user, type: Grape::API::Boolean, desc: "新用户可用"
          optional :is_always, type: String, desc: "是否总是弹出"
          optional :is_fullscreen, type: String, desc: "是否全屏"
        end
        put do
          authorize_and_update_resource
        end

        desc "Destroy page_popup", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
