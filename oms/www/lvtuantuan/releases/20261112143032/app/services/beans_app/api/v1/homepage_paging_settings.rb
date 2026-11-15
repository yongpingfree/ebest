# frozen_string_literal: true

module BeansApp
  class API::V1::HomepagePagingSettings < ::API
    namespace :homepage_paging_settings, desc: "首页分页配置API" do

      helpers do
        def default_order
          "position asc, id DESC"
        end

        def includes
          [:custom_page]
        end
      end

      desc "首页分页配置列表", {
        success: API::Entities::HomepagePagingSetting,
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
