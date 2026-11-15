# frozen_string_literal: true

module BeansAdmin
  class API::V1::RoleTemplates < ::API

    namespace :role_templates, desc: "管理员权限模板" do
      helpers do
        def permitted_params
          [:name, permissions: []]
        end
      end

      desc "权限模板列表", {
        success: API::Entities::RoleTemplate,
        is_array: true,
      }
      paginate
      params do
        optional :name_cont, type: String
      end
      get do
        authorize_and_response_collection
      end

      desc "创建权限模板", {
        success: API::Entities::RoleTemplate
      }
      params do
        requires :all, using: API::Entities::RoleTemplate.documentation.dup.extract!(:name)
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "权限模板详情", {
          success: API::Entities::RoleTemplate
        }
        get do
          authorize_and_response_resource
        end

        desc "修改权限模板", {
          success: API::Entities::RoleTemplate
        }
        params do
          optional :all, using: API::Entities::RoleTemplate.documentation
        end
        put do
          authorize_and_update_resource
        end
      end
    end
  end
end
