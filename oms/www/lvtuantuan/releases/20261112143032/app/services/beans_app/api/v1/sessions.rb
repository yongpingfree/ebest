# frozen_string_literal: true

module BeansApp
  class API::V1::Sessions < ::API
    helpers ::ApiHelpers::MobileHelper
    helpers ::ApiHelpers::EmailHelper
    helpers ::ApiHelpers::ShoplineHelper

    namespace :sessions, desc: "Sessions API" do
      desc "用户登录", {
        skip_authentication: true
      }
      params do
        requires :login, type: String, desc: "可传 email 或手机号，手机号码(前端需要传61)"
        requires :credential_type, type: Symbol, values: [:code, :password], desc: "登录方式：密码还是验证码"
        requires :credential, type: String, desc: "密码或验证码"
      end
      post do
        login = params[:login].to_s.strip
        login_type = login.include?("@") ? :email : :mobile
        credential_type = params[:credential_type]
        credential = params[:credential].to_s.strip

        # 查找用户
        member = if login_type == :email
          MagicBean::Member.where("LOWER(email) = ?", login.downcase).first        
        else
          check_phone_number!(login)
          MagicBean::Member.find_by(mobile: login)
        end

        response_error(I18n.t("error.user.not_found")) unless member

        # 避免暴力破解，10分钟内只能尝试登录5次
        redis = Rails.cache.redis
        login_key = "user-#{member.id}-login-times"
        login_times = redis.get(login_key).to_i
        if login_times.positive?
          response_error(I18n.t("error.user.login_more_than_times")) if login_times >= MagicBean::Member::MAX_LOGIN_TRY
          redis.incr(login_key)
        else
          redis.set(login_key, 1, ex: 10.minutes)
        end

        user = member.user

        return response_error(I18n.t("grape.users.failed_to_login"), 403) if user.nil?
        return response_error(I18n.t("grape.users.account_deleted"), 403) if user.deleted_by_user?

        if credential_type == :password # 密码登录
          if !user.has_password? || !user.authenticate(credential)
            response_error(I18n.t("error.user.incorrect_password"))
          end
        else # 验证码登录
          if login_type == :mobile # 手机短信验证码
            check_verification_code!(login, credential, :login)
          elsif login_type == :email # email 验证码
            check_email_verification_code!(login, credential, :login)
          end
        end

        response_error(I18n.t("grape.users.account_deleted"), 403) if user.deleted_by_user?

        redis.del(login_key)
        session[:user_id] = member.user_id
        { access_token: JsonWebToken.encode({ certificate: member.user_id }) }
      end

      desc "用户Shoplie登录", {
        skip_authentication: true
      }
      post "shopline" do
        user = MagicBean::ShoplineUser.find_by(email: params[:acct].to_s.strip)
        response_shopline_error(I18n.t("error.user.not_found", locale: :en)) unless user
        response_shopline_error(I18n.t("error.user.incorrect_password", locale: :en)) unless user.authenticate(params[:pwd].to_s.strip)
        
        token = generate_multipass_token(user)

        response_shopline_success({ token: token })
      end

      desc "sign out", {
        skip_authentication: true
      }
      delete do
        session[:user_id] = nil
        response_success
      end

      desc "指纹登录", {
        skip_authentication: true
      }
      params do
        requires :signature, type: String, desc: "指纹签名"
      end
      post "fingerprint" do
        user = MagicBean::User.fingerprint_signatures_contains_any(params[:signature])

        if user
          session[:user_id] = user.id
          { access_token: JsonWebToken.encode({ certificate: user.id }) }
        else
          response_error(I18n.t("error.user.not_found"))
        end
      end
    end
  end
end
