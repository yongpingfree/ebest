# frozen_string_literal: true

module BeansAdmin
  class API::V1::Sessions < ::API
    helpers ::ApiHelpers::MobileHelper

    namespace :sessions, desc: "管理员登录接口" do
      desc "管理员登录", {
        success: API::Entities::AdminUser
      }
      params do
        requires :mobile, type: String, desc: "手机号码"
        requires :code, type: String, desc: "验证码"
      end
      post "login" do
        if current_admin_user.present?
          response_error("您已登录！")
        elsif admin_user = MagicBean::AdminUser.active.find_by(mobile: params[:mobile])
          check_verification_code!(params[:mobile], params[:code], "login")

          sign_in_admin_user admin_user

          present admin_user, with: API::Entities::AdminUser
        else
          response_error("不存在该账号")
        end
      end

      desc "管理员使用密码登录", {
        success: API::Entities::AdminUser
      }
      params do
        requires :mobile, type: String, desc: "手机号码"
        requires :password, type: String, desc: "密码"
      end
      post "login_with_password" do
        params.map { |k, v| v.strip! }

        if current_admin_user.present?
          sign_out_admin_user
        end

        admin_user = MagicBean::AdminUser.find_by(mobile: params[:mobile])

        response_error("手机号码或密码不正确") if admin_user.nil?
        response_error("账号被锁定，请联系管理员") if admin_user.access_locked?

        if admin_user.try(:authenticate, params[:password])
          if admin_user.banned?
            sign_out_admin_user
            response_error("该账号已被禁用，若有疑问请联系超级管理员！")
          end
          if admin_user.permissions.blank?
            sign_out_admin_user
            response_error("该账号没有权限，若有疑问请联系超级管理员！")
          end

          admin_user.reset_failed_attempts
          sign_in_admin_user admin_user
          present admin_user, with: API::Entities::AdminUser
        else
          admin_user.increment_failed_attempts
          if admin_user.access_locked?
            response_error("账号被锁定，请联系管理员")
          else
            remaining_attempts = MagicBean::AdminUser::MAX_LOGIN_ATTEMPTS - admin_user.failed_attempts
            response_error("手机号码/密码不正确，再错#{remaining_attempts}次账号将会被锁定。")
          end
        end
      end

      desc "管理员退出登录", {
        detail: { code: 200, message: "OK" }.to_s
      }
      delete do
        if current_admin_user.present?
          sign_out_admin_user
          response_success
        else
          response_error("您尚未登录！")
        end
      end

      desc "当前登录管理员", {
        success: API::Entities::AdminUser
      }
      get "current_admin_user" do
        authenticate!

        present current_admin_user, with: API::Entities::AdminUser
      end

      desc "重置密码", {
        success: API::Entities::AdminUser
      }
      params do
        requires :mobile, type: String, desc: "手机号码"
        requires :code, type: String, desc: "验证码"
        requires :password, type: String, desc: "密码"
        requires :password_confirmation, type: String, desc: "密码确认"
      end
      put "reset_password" do
        admin_user = MagicBean::AdminUser.active.find_by(mobile: params[:mobile])
        if admin_user
          check_verification_code!(params[:mobile], params[:code], "reset_password")
          if params[:password] == params[:password_confirmation]
            admin_user.password = params[:password]
            standard_save(admin_user, API::Entities::AdminUser)
          else
            response_error("输入密码不一致")
          end
        else
          response_error("不存在该账号")
        end
      end
    end

    namespace :verification_code, desc: "验证码接口" do
      desc "发送验证码", {
        detail: { code: 200, message: "OK",
                  result: {verification_code: "only development"}
                }.to_s
      }
      params do
        requires :mobile, type: String, desc: "手机号码"
        requires :event, type: String, desc: "事件类型", values: ["login", "reset_password"]
      end
      post do
        check_phone_number!(params[:mobile])

        admin_user = MagicBean::AdminUser.active.find_by(mobile: params[:mobile])
        response_error("不存在该账号") if admin_user.blank?

        vc = MagicBean::VerificationCode.new(params[:mobile], params[:event])

        if vc.code.present? && !vc.can_send_again?
          response_error("验证码已经发送")
        else
          vc.send_code

          result = {}
          result[:verification_code] = vc.code if Rails.env.development?

          response_success("已发送验证码", result: result)
        end
      end
    end
  end
end
