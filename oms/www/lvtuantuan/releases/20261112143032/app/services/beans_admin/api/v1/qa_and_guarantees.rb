# frozen_string_literal: true

module BeansAdmin
  class API::V1::QaAndGuarantees < ::API

    namespace :qa_and_guarantees, desc: "答疑&保障 API" do

      helpers do
        def permitted_params
          resource_class.globalize_attribute_names + [:web_image]
        end

        def includes
          [:translations]
        end
      end

      desc "答疑&保障列表", {
        success: API::Entities::QaAndGuarantee,
        is_array: true
      }
      paginate
      params do
        optional :skip_role_authentication, type: Boolean, desc: "是否跳过权限验证"
      end
      get do
        authorize_and_response_collection(skip_role_authentication: params[:skip_role_authentication])
      end

      desc "新增答疑&保障", {
        success: API::Entities::QaAndGuarantee
      }
      params do
        requires :all, using: API::Entities::QaAndGuarantee.documentation.dup.extract!(:title_zh_cn, :image_zh_cn)
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do

        desc "答疑&保障详情", {
          success: API::Entities::QaAndGuarantee
        }
        get do
          authorize_and_response_resource
        end

        desc "更新答疑&保障", {
          success: API::Entities::QaAndGuarantee
        }
        params do
          requires :all, using: API::Entities::QaAndGuarantee.documentation.dup.extract!(:title_zh_cn, :image_zh_cn)
        end
        put do
          authorize_and_update_resource
        end

        desc "删除答疑&保障", {
          success: API::Entities::QaAndGuarantee
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
