# frozen_string_literal: true

module BeansAdmin
  class API::V1::MultiLangConfigs < ::API
    namespace :multi_lang_configs, desc: "全站多语系内容 API" do
      helpers do
        def permitted_params
          resource_class.globalize_attribute_names
        end

        def includes
          [:translations, :store]
        end
      end

      desc "配置列表", {
        success: API::Entities::MultiLangConfig,
        is_array: true
      }
      paginate
      params do
        optional :q, type: Hash do
          optional :translations_name_cont, types: String, desc: "名称搜索"
        end
      end
      get do
        authorize_and_response_collection
      end

      route_param :id do
        desc "详情", {
          success: API::Entities::MultiLangConfig
        }
        get do
          authorize_and_response_resource
        end

        desc "更新", {
          success: API::Entities::MultiLangConfig
        }
        put do
          authorize_and_update_resource
        end
      end
    end
  end
end
