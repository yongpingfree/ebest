# frozen_string_literal: true

module BeansApp
  class API::V1::CouponPackages < ::API
    namespace :coupon_packages, desc: "优惠券礼包" do
      route_param :code do
        helpers do
          def find_by_key
            :code
          end

          def end_of_association_chain
            resource_class.published
          end
        end

        desc "优惠券礼包详情", {
          success: API::Entities::CouponPackage,
          action_type: "viewed",
          page_type: "coupon_package",
          skip_authentication: true
        }
        get do
          authorize_and_response_resource
        end

        desc "领取优惠券礼包", {
          success: API::Entities::CouponPackage
        }
        post "assign_coupon_template" do
          authorize_and_run_member_action(:assign_coupon_template, {}, current_user)
        end
      end
    end
  end
end
