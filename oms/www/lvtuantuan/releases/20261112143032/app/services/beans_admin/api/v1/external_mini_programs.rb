# frozen_string_literal: true

module BeansAdmin
  class API::V1::ExternalMiniPrograms < ::API
    namespace :external_mini_programs, desc: "外部小程序链接 API" do
      helpers do
        def permitted_params
          [:name, :origin_id, :app_id, :path, :env_version]
        end
      end

      desc "外部小程序链接列表", {
        success: API::Entities::ExternalMiniProgram,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "新增外部小程序链接", {
        success: API::Entities::ExternalMiniProgram
      }
      params do
        requires :name, type: String, desc: "名字"
        requires :path, type: String, desc: "小程序路径"
        requires :origin_id, type: String, desc: "原始 ID，`gh` 开头字符串"
        requires :app_id, type: String, desc: "AppID，`wx` 开头字符串"
        optional :version, type: Integer, desc: "小程序版本：正式版，开发版、体验版"
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "外部链接小程序详情", {
          success: API::Entities::ExternalMiniProgram
        }
        get do
          authorize_and_response_resource
        end

        desc "更新外部小程序链接", {
          success: API::Entities::ExternalMiniProgram
        }
        params do
          requires :name, type: String, desc: "名字"
          requires :path, type: String, desc: "小程序路径"
          requires :origin_id, type: String, desc: "原始 ID，`gh` 开头字符串"
          requires :app_id, type: String, desc: "AppID，`wx` 开头字符串"
        end
        put do
          authorize_and_update_resource
        end

        desc "删除外部小程序链接", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
