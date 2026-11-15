# frozen_string_literal: true

module BeansAdmin
  class API::V1::MinePageActivitySettings < ::API

    namespace :mine_page_activity_settings, desc: "我的页面活动配置 API" do

      helpers do
        def permitted_params
          resource_class.globalize_attribute_names + [:icon, :custom_page_id, :position, :enabled, :store_id, :path]
        end

        def default_order
          "position asc, id desc"
        end

        def includes
          [:custom_page, :translations]
        end
      end

      desc "我的页面活动配置列表", {
        success: API::Entities::MinePageActivitySetting,
        is_array: true
      }
      paginate
      params do
        optional :translations_name_cont, types: String, desc: "名称搜索"
      end
      get do
        authorize_and_response_collection
      end

      desc "新增我的页面活动配置", {
        success: API::Entities::MinePageActivitySetting
      }
      params do
        requires :name_zh_cn, type: String
        requires :name_zh_tw, type: String
        requires :name_en, type: String
        requires :icon, type: String
        optional :custom_page_id, type: Integer
        requires :position, type: Integer
        requires :enabled, type: Boolean
        optional :path, type: String, desc: "跳转页面路径"
      end
      post do
        params[:store_id] = current_store_id
        authorize_and_create_resource
      end

      route_param :id do
        desc "我的页面活动配置详情", {
          success: API::Entities::MinePageActivitySetting
        }
        get do
          authorize_and_response_resource
        end

        desc "更新我的页面活动配置", {
          success: API::Entities::MinePageActivitySetting
        }
        params do
          optional :name_zh_cn, type: String
          optional :name_zh_tw, type: String
          optional :name_en, type: String
          optional :icon, type: String
          optional :custom_page_id, type: Integer
          optional :position, type: Integer
          optional :enabled, type: Boolean
          optional :path, type: String
        end
        put do
          params.delete(:store_id)
          authorize_and_update_resource
        end

        desc "删除我的页面活动配置", {
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
