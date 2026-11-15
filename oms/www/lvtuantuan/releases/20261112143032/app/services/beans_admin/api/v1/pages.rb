# frozen_string_literal: true

module BeansAdmin
  class API::V1::Pages < ::API
    # 优惠券模板 API

    namespace :pages, desc: "独立页面 API" do
      helpers do
        def permitted_params
          [:kind, :name, :content, :desc, :cover, :position]
        end

        def default_order
          ["position ASC", "created_at DESC"]
        end
      end

      desc "独立页面列表", {
        success: API::Entities::Page,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "新增独立页面", {
        success: API::Entities::Page
      }
      params do
        requires :name, type: String, desc: "页面名"
        requires :content, type: String, desc: "内容"
        optional :kind, type: String, desc: "类型", values: ["article"], default: "article"
        requires :cover, type: String, desc: "封面"
        optional :desc, type: String, desc: "简介"
        optional :position, type: String, desc: "位置"
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "独立页面详情", {
          success: API::Entities::Page
        }
        get do
          authorize_and_response_resource
        end

        desc "更新独立页面", {
          success: API::Entities::Page
        }
        params do
          optional :name, type: String, desc: "页面名"
          optional :content, type: String, desc: "内容"
          optional :position, type: String, desc: "位置"
        end
        put do
          authorize_and_update_resource
        end

        desc "删除独立页面", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
