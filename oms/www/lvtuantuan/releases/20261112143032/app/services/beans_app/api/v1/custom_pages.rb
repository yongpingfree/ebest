# frozen_string_literal: true

module BeansApp
  class API::V1::CustomPages < ::API
    # 自定义页面 API

    namespace :custom_pages, desc: "自定义页面 API" do

      helpers do
        def find_by_key
          :en_name
        end

        def resource
          @resource ||= end_of_association_chain.includes(includes).ransack({ store_id_eq: current_store_id }).result.find_by!(en_name: params[:en_name])
        end
      end

      desc "获取自定义页面", {
        success: API::Entities::CustomPage,
        is_array: true,
        action_type: "searched",
        page_type: "custom_page",
        skip_authentication: true
      }
      paginate
      get do
        response_collection
      end

      desc "商品搜索顶部banner", {
        is_array: true,
        skip_authentication: true
      }
      params do
        optional :keyword, types: [String, Array], desc: "搜索关键词", coerce_with: ->(val) { val.to_s.split(" ") }
      end
      get "banner_top" do
        if params[:keyword].blank?
          []
        else
          MagicBean::ShareSetting.where(target_type: "MagicBean::CustomPage").includes(:target).ransack({search_words_cont_any: params[:keyword]}).result.map do |setting|
            {
              search_cover: setting.search_cover,
              app_path: setting.target.app_path,
              mini_program_path: setting.target.mini_program_path
            }
          end
        end
      end

      route_param :en_name do
        desc "自定义页面详情", {
          success: API::Entities::CustomPage,
          action_type: "viewed",
          page_type: "custom_page",
          skip_authentication: true
        }
        get do
          if resource.redis_content.nil?
            response_resource
          else
            present JSON.parse(resource.redis_content)
          end
        end
      end
    end
  end
end
