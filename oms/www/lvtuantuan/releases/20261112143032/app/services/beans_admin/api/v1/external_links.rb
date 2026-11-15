# frozen_string_literal: true

module BeansAdmin
  class API::V1::ExternalLinks < ::API
    namespace :external_links, desc: "外部链接 API" do
      helpers do
        def permitted_params
          [:name, :link]
        end
      end

      desc "外部链接列表", {
        success: API::Entities::ExternalLink,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "新增外部链接", {
        success: API::Entities::ExternalLink
      }
      params do
        requires :name, type: String, desc: "名字"
        requires :link, type: String, desc: "链接"
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "外部链接详情", {
          success: API::Entities::ExternalLink
        }
        get do
          authorize_and_response_resource
        end

        desc "更新外部链接", {
          success: API::Entities::ExternalLink
        }
        params do
          requires :name, type: String, desc: "名字"
          requires :link, type: String, desc: "链接"
        end
        put do
          authorize_and_update_resource
        end

        desc "删除外部链接", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
