# frozen_string_literal: true

module BeansAdmin
  class API::V1::SignInActivities < ::API
    # 签到活动 API
    namespace :sign_in_activities, desc: "签到活动 API" do
      helpers do
        def default_order
          ["id desc"]
        end

        def permitted_params
          resource_class.globalize_attribute_names + [:banner, :detail_image, :start_at, :end_at, :enabled, :reward_integral_each_time, :extra_reward_type, :sign_in_times, :extra_reward_integral]
        end

        def includes
          [:translations]
        end
      end

      desc "签到活动列表", {
        success: API::Entities::SignInActivity,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "新增签到活动", {
        success: API::Entities::SignInActivity
      }
      params do
        requires :all, using: API::Entities::SignInActivity.documentation.dup.extract!(:title_zh_cn, :detail_image, :start_at, :end_at, :enabled, :reward_integral_each_time, :extra_reward_type, :sign_in_times, :extra_reward_integral)
        optional :all, using: API::Entities::SignInActivity.documentation.dup.extract!(:title_zh_tw, :title_en, :banner)
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "签到活动详情", {
          success: API::Entities::SignInActivity
        }
        get do
          authorize_and_response_resource
        end

        desc "更新签到活动", {
          success: API::Entities::SignInActivity,
          skip_store_id: true
        }
        params do
          optional :all, using: API::Entities::SignInActivity.documentation.dup.extract!(:title_zh_cn, :title_zh_tw, :title_en, :banner, :detail_image, :start_at, :end_at, :enabled, :reward_integral_each_time, :extra_reward_type, :sign_in_times, :extra_reward_integral)
        end
        put do
          authorize_and_update_resource
        end
      end
    end
  end
end
