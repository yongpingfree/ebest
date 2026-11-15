# frozen_string_literal: true

module BeansApp
  class API::V1::Pages < ::API
    # 独立页面 API

    namespace :pages, desc: "独立页面 API" do
      route_param :id do
        desc "获取页面详情", {
          success: API::Entities::Page,
          skip_authentication: true
        }
        get do
          response_resource
        end
      end
    end
  end
end
