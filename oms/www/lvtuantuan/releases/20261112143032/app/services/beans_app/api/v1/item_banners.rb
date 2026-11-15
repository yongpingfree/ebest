# frozen_string_literal: true

module BeansApp
  class API::V1::ItemBanners < ::API
    namespace :item_banners, desc: "产品Banner API" do

      route_param :id do
        desc "商品Banner点击统计",  {
          success: API::Entities::SuccessfulResult,
          skip_authentication: true
        }
        post "click" do
          banner_click =
            begin
              # 有时因为并发，create会失败
              resource.item_banner_clicks.find_or_create_by!(date: Date.current)
            rescue
              resource.item_banner_clicks.find_by(date: Date.current)
            end

          banner_click.increment!(:count)

          response_success
        rescue
          # 异常直接返回200，避免app报错
          response_success
        end
      end
    end
  end
end
