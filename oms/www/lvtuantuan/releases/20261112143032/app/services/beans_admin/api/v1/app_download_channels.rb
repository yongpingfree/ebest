# frozen_string_literal: true

module BeansAdmin
  class API::V1::AppDownloadChannels < ::API
    # 优惠券模板 API

    namespace :app_download_channels, desc: "APP 下载渠道 API" do
      helpers do
        def permitted_params
          [:name]
        end

        def default_order
          ["created_at DESC"]
        end
      end

      desc "APP 下载渠道列表", {
        success: API::Entities::AppDownloadChannel,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "新增APP 下载渠道", {
        success: API::Entities::AppDownloadChannel
      }
      params do
        requires :name, type: String, desc: "渠道名"
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "APP 下载渠道详情", {
          success: API::Entities::AppDownloadChannel
        }
        get do
          authorize_and_response_resource
        end

        desc "更新APP 下载渠道", {
          success: API::Entities::AppDownloadChannel
        }
        params do
          optional :name, type: String, desc: "渠道名"
        end
        put do
          authorize_and_update_resource
        end

        desc "删除APP 下载渠道", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
