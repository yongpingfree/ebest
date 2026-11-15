# frozen_string_literal: true

module BeansAdmin
  class API::V1::HomepagePagingSettings < ::API

    namespace :homepage_paging_settings, desc: "首页分页配置 API" do

      helpers do
        def permitted_params
          [:name, :image, :selected_image, :background_image, :custom_page_id, :position, :show_banners, :show_image_notice, :store_id, banners: {}, image_notice: {}]
        end

        def default_order
          "position asc, id desc"
        end

        def includes
          [:custom_page]
        end
      end

      desc "首页分页配置列表", {
        success: API::Entities::SimpleHomepagePagingSetting,
        is_array: true
      }
      paginate
      params do
        optional :name_cont, types: String, desc: "名称搜索"
      end
      get do
        authorize_and_response_collection
      end

      desc "新增首页分页配置", {
        success: API::Entities::HomepagePagingSetting
      }
      params do
        requires :name, type: String
        requires :image, type: String
        requires :custom_page_id, type: Integer
        requires :position, type: Integer
      end
      post do
        params[:store_id] = current_store_id
        authorize_and_create_resource
      end

      route_param :id do
        desc "首页分页配置详情", {
          success: API::Entities::HomepagePagingSetting
        }
        get do
          authorize_and_response_resource
        end

        desc "更新首页分页配置", {
          success: API::Entities::HomepagePagingSetting
        }
        params do
          optional :name, type: String
          optional :image, type: String
          optional :custom_page_id, type: Integer
          optional :position, type: Integer
        end
        put do
          params.delete(:store_id)
          authorize_and_update_resource
        end

        desc "删除首页分页配置", {
          detail: <<-NOTES.strip_heredoc
            ```json
            {
              code: 200,
              message: "ok"
            }
            ```
          NOTES
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
