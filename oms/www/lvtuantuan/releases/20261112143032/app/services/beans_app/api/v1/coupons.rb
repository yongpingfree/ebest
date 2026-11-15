# frozen_string_literal: true

module BeansApp
  class API::V1::Coupons < ::API
    # 优惠券 API

    namespace :coupons, desc: "优惠券 API" do
      helpers do
        def end_of_association_chain
          if params[:status].present?
            resource_class.public_send(params[:status])
          else
            resource_class
          end.where(store_id: [nil, current_store_id])
        end

        def includes
          [:store, :coupon_template]
        end
      end
      desc "优惠券列表", {
        success: API::Entities::Coupon,
        is_array: true
      }
      paginate
      params do
        optional :status, type: String, desc: "状态", values: ["pending", "inactive", "usable", "used", "expired"]
      end
      get do
        authorize_and_response_collection
      end

      route_param :id do
        desc "优惠券详情", {
          success: API::Entities::Coupon
        }
        get do
          authorize_and_response_resource
        end
      end
    end
  end
end
