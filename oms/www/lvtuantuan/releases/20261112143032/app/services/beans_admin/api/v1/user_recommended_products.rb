# frozen_string_literal: true
module BeansAdmin
  class API::V1::UserRecommendedProducts < ::API

    namespace :user_recommended_products, desc: "UserRecommendedProducts API" do
      helpers do
        def includes
          [user: :member]
        end
      end

      desc "UserRecommendedProducts list", {
        success: API::Entities::UserRecommendedProduct,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      route_param :id do
        desc "UserRecommendedProduct detail", {
          success: API::Entities::UserRecommendedProduct
        }
        get do
          authorize_and_response_resource
        end

        desc "Destroy user_recommended_products", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
