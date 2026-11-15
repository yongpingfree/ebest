# frozen_string_literal: true

module BeansApp
  class API::V1::BannerClicks < ::API
    namespace :banner_clicks, desc: "首页 banner 点击统计 API" do
      desc "新增一次点击统计", {
        skip_authentication: true
      }
      params do
        requires :url, type: String, desc: "图片地址"
      end
      post do
        banner_click = MagicBean::BannerClick.find_or_create_by(date: Date.today, url: params[:url])
        banner_click.increment!(:count)

        status 201
        body false
      end
    end
  end
end
