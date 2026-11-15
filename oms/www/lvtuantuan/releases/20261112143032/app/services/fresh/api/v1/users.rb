# frozen_string_literal: true

module Fresh
  class API::V1::Users < ::API
    # 用户 API

    namespace :users, desc: "用户 API" do
      desc "同步用户信息", {
        success: API::Entities::SuccessfulResult
      }
      params do
        use :sign_params
        requires :unionid, type: String, desc: "unionid"
        requires :balance, type: Integer, desc: "余额(分)(1~3000)"
      end
      post do
        begin
          response_error "只同步余额1~3000的账户" unless params[:balance].between?(1, 3000)

          user = MagicBean::User.find_or_create_by!(ebest_platform_unionid: params[:unionid])
          response_error "该用户已同步过" if user.synce_from_fresh_at

          MagicBean::CouponTemplate.assign_coupon_from_fresh_balance(user, params[:balance])
          user.update_columns(synce_from_fresh_at: Time.current)
          response_success
        rescue StandardError => e
          response_error e.message
        end
      end
    end
  end
end
