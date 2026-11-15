# frozen_string_literal: true

module BeansAdmin
  class API::V1::AgeVerifications < ::API
    namespace :age_verifications, desc: "年龄验证 API" do

      helpers do
        def permitted_params
          resource_class.globalize_attribute_names + [:image, :parent_category_id, :parent_web_category_id]
        end

        def includes
          [:translations, parent_category: [:translations]]
        end
      end

      desc "列表", {
        success: API::Entities::AgeVerification,
        is_array: true
      }
      paginate
      params do
        optional :q, type: Hash do
          optional :translations_title_cont, types: String, desc: "名称搜索"
        end
        optional :skip_role_authentication, type: Boolean, desc: "是否跳过权限验证"
      end
      get do
        authorize_and_response_collection(skip_role_authentication: params[:skip_role_authentication])
      end

      desc "新增", {
        success: API::Entities::AgeVerification
      }
      params do
        requires :all, using: API::Entities::AgeVerification.documentation.dup.extract!(:title_zh_cn, :content_zh_cn, :image, :parent_category_id, :title_zh_tw, :title_en, :content_zh_tw, :content_en)
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "详情", {
          success: API::Entities::AgeVerification
        }
        get do
          authorize_and_response_resource
        end

        desc "更新", {
          success: API::Entities::AgeVerification
        }
        put do
          authorize_and_update_resource
        end

        desc "删除", {
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
