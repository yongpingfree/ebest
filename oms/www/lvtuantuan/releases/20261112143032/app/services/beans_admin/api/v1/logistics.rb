# frozen_string_literal: true
module BeansAdmin
  class API::V1::Logistics < ::API

    namespace :logistics, desc: "物流管理 API" do
      helpers do
        def includes
          [:order]
        end
      end
      desc "物流管理列表", {
        success: API::Entities::Logistic,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      route_param :id do
        desc "物流管理详情", {
          success: API::Entities::Logistic
        }
        get do
          authorize_and_response_resource
        end

        desc "删除物流", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
