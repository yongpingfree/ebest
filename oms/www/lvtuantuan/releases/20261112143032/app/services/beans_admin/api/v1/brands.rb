# frozen_string_literal: true

module BeansAdmin
  class API::V1::Brands < ::API

    namespace :brands, desc: "商品品牌 API" do

      helpers do
        def permitted_params
          resource_class.globalize_attribute_names + [:cover, :position]
        end

        def default_order
          "position asc"
        end

        def includes
          [:translations]
        end
      end

      desc "品牌列表", {
        success: API::Entities::Brand,
        is_array: true
      }
      paginate
      params do
        optional :q, type: Hash do
          optional :translations_name_cont, types: String, desc: "名称搜索"
        end
        optional :skip_role_authentication, type: Boolean, desc: "是否跳过权限验证"
      end
      get do
        authorize_and_response_collection(skip_role_authentication: params[:skip_role_authentication])
      end

      desc "新增商品品牌", {
        success: API::Entities::Brand
      }
      params do
        requires :name_zh_cn, type: String, desc: "品牌名称"
        requires :cover, type: String, desc: "品牌封面图"
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "品牌详情", {
          success: API::Entities::Brand
        }
        get do
          authorize_and_response_resource
        end

        desc "更新商品品牌", {
          success: API::Entities::Brand
        }
        params do
          optional :name, type: String, desc: "品牌名称"
          optional :cover, type: String, desc: "品牌封面图"
        end
        put do
          authorize_and_update_resource
        end

        desc "删除商品品牌", {
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
