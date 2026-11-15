# frozen_string_literal: true

module BeansApp
  class API::V1::WebBanners < ::API
    namespace :web_banners, desc: "英文网页 Banner API" do
      desc "Banner 数据",  {
        skip_authentication: true
      }
      params do
        requires :page_location_in, type: Array, values: MagicBean::WebBanner.page_locations.keys, desc: "页面位置数组"
      end
      get do
        MagicBean::WebBanner.of_store(current_store_id).slice(*params[:page_location_in])
      end
    end
  end
end
