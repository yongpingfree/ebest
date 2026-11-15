# frozen_string_literal: true

module BeansApp
  class API::V1::MinePageActivitySettings < ::API
    namespace :mine_page_activity_settings, desc: "我的页面活动配置API" do

      helpers do
        def default_order
          "position asc, id DESC"
        end

        def includes
          [:custom_page, :translations]
        end

        def end_of_association_chain
          MagicBean::MinePageActivitySetting.where(enabled: true)
        end  
      end

      desc "我的页面活动配置列表", {
        success: API::Entities::MinePageActivitySetting,
        is_array: true,
        skip_authentication: true
      }
      paginate
      get do
        params[:store_id_eq] = current_store_id
        authorize_and_response_collection
      end
    end
  end
end
