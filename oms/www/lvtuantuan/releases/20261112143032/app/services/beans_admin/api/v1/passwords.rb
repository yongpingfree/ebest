# frozen_string_literal: true

module BeansAdmin
  class API::V1::Passwords < ::API
    namespace :passwords, desc: "管理员重置密码" do
      desc "重置密码", {
        detail: { code: 200, message: "OK" }
      }
      params do
        requires :mobile, type: String, desc: "手机号码"
        requires :password, type: String, desc: "密码"
        requires :password_confirmation, type: String, desc: "密码确认"
        requires :code, type: String, desc: "验证码"
      end
      put do
        response_error("您已登录！") if current_admin_user.present?

        admin_user = MagicBean::AdminUser.active.find_by(mobile: params[:mobile])
        response_error("不存在该账号") if admin_user.blank?

        verification_code = MagicBean::VerificationCode.build_reset_password_object(params[:mobile])
        response_error("验证码不正确") unless verification_code.verify(params[:code])

        if admin_user.update(raw_parameters(params).permit(:password, :password_confirmation))

          verification_code.code = nil

          response_success
        else
          response_record_error(admin_user)
        end
      end
    end
  end
end
