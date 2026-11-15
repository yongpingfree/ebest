# frozen_string_literal: true
module BeansAdmin
  class API::V1::WebBanners < ::API
    namespace :web_banners, desc: "英文网站Banner管理 API" do
      helpers do
        def permitted_params
          [
            :remark, :displayed, :page_location,
            web_banner_items_attributes: [
              :id, :position, :start_at, :end_at, :_destroy,
              :desktop_image_url, :mobile_image_url,
              :nav_path_type, :nav_path_id
            ]
          ]
        end

        def build_resource
          @resource = end_of_association_chain.new(resource_params.merge({
            store_id: current_store_id
          }))
        end

        def includes
          [:store, :web_banner_items]
        end
      end

      desc "英文网站Banner列表", {
        success: API::Entities::SimpleWebBanner,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "创建英文网站Banner", {
        success: API::Entities::WebBanner
      }
      params do
        requires :page_location, type: String
        optional :web_banner_items_attributes, type: Array do
          # 使用model的来校验必填项，这里不再设置requires, grape再处理数组错误信息时有些麻烦，web_banner_items_attributes[0][:desktop_image_url]，很难在yml里面处理
          optional :all, using: API::Entities::WebBannerItem.documentation.slice(
            :desktop_image_url, :mobile_image_url, :position, :start_at, :end_at
          )
        end
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "英文网站Banner活动详情", {
          success: API::Entities::WebBanner
        }
        get do
          authorize_and_response_resource
        end

        desc "更新英文网站Banner活动", {
          success: API::Entities::WebBanner
        }
        params do
          requires :page_location, type: String
          optional :web_banner_items_attributes, type: Array do
            optional :all, using: API::Entities::WebBannerItem.documentation.slice(
              :image_url, :position, :start_at, :end_at
            )
          end
        end
        put do
          authorize_and_update_resource
        end

        desc "删除英文网站Banner活动", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
