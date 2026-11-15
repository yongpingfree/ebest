# frozen_string_literal: true
module BeansAdmin
  class API::V1::PromoCodes < ::API
    namespace :promo_codes, desc: "PromoCodes API" do
      helpers do
        def includes
          [:orders]
        end

        def end_of_association_chain
          if params[:is_used].nil?
            resource_class
          else
            params[:is_used] ? resource_class.used : resource_class.unused
          end
        end
      end

      desc "PromoCodes list", {
        success: API::Entities::PromoCode,
        is_array: true
      }
      params do
        optional :is_used, type: Boolean
      end
      paginate
      get do
        authorize_and_response_collection
      end

      route_param :id do
        desc "PromoCode detail", {
          success: API::Entities::PromoCode
        }
        get do
          authorize_and_response_resource
        end

        desc "Destroy promo_code", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
