# frozen_string_literal: true
module BeansAdmin
  class API::V1::Coupons < ::API

    namespace :coupons, desc: "优惠券API" do
      helpers do
        def includes
          ["user", "order"]
        end
      end

      desc "优惠券列表", {
        success: API::Entities::Coupon,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection(present: { with: BeansAdmin::API::Entities::Coupon })
      end

      route_param :id do
        desc "优惠券详情", {
          success: API::Entities::Coupon
        }
        get do
          authorize_and_response_resource
        end

        desc "发放优惠券给用户", {
          success: API::Entities::Coupon
        }
        params do
          requires :user_id, type: Integer, desc: "用户 id"
        end
        put "assign_to_user" do
          user = MagicBean::User.accessible_by(current_ability).find(params[:user_id])
          log_message = "发放优惠券给用户: #{user.nickname}"
          authorize_and_run_member_action(:assign_to_user, { log_message: log_message }, user, nil, nil, true)
        end

        desc "删除优惠券", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
