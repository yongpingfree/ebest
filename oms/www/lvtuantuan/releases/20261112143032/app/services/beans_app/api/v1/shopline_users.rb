# frozen_string_literal: true

module BeansApp
  class API::V1::ShoplineUsers < ::API
    helpers ::ApiHelpers::EmailHelper
    helpers ::ApiHelpers::MobileHelper
    helpers ::ApiHelpers::ShoplineHelper

    namespace :shopline_users, desc: "用户API" do

      desc "获取邮箱验证码", {
        skip_authentication: true
      }
      params do
        requires :acct, type: String, coerce_with: ->(val) { val.to_s.strip }, desc: "邮箱"
        requires :event, type: String, values: ["shopline_signup", "shopline_reset_phone", "shopline_reset_email", "shopline_new_email", "shopline_reset_password",]
      end
      get "email_verification_code" do
        email = params[:acct]
        event = params[:event]
        if event.in?(["shopline_reset_phone", "shopline_reset_email"])
          response_shopline_error(I18n.t("error.user.not_found", locale: :en)) unless MagicBean::ShoplineUser.exists?(email: email)
        end

        vc = MagicBean::EmailVerificationCode.new(email, event)
        vc.send_code
        response_shopline_success
      end

      # desc "获取短信验证码", {
      #   skip_authentication: true
      # }
      # params do
      #   requires :mobile, type: String, coerce_with: ->(val) { val.to_s.strip }, desc: "邮箱"
      #   requires :event, type: String, values: ["shopline_new_phone", "shopline_reset_phone", "shopline_reset_email"]
      # end
      # get "verification_code" do
      #   mobile = params[:mobile]
      #   event = params[:event]

      #   # 发短信的要先格式化手机号，保存数据库的不需要
      #   sms_number = shopline_format_phone(mobile)
      #   shopline_check_phone_number!(sms_number)

      #   vc = MagicBean::VerificationCode.new(sms_number, event)
      #   vc.send_code
      #   response_shopline_success
      # end

      desc "注册", {
        skip_authentication: true
      }
      params do
        requires :acct, type: String, coerce_with: ->(val) { val.to_s.strip }, desc: "邮箱"
        requires :verifycode, type: String, coerce_with: ->(val) { val.to_s.strip }, desc: "验证码"
        requires :pwd, type: String, coerce_with: ->(val) { val.to_s.strip }, desc: "密码"
      end
      post "signup" do
        response_shopline_error("The email has been registered") if MagicBean::ShoplineUser.exists?(email: params[:acct])
        shopline_check_email_verification_code!(params[:acct], params[:verifycode], :shopline_signup)

        user = MagicBean::ShoplineUser.new(
          email: params[:acct],
          password: params[:pwd]
        )

        # email在验证码验证时已经验证过了，只剩下密码的验证，保存失败则返回密码错误信息
        response_shopline_error("Password must be 6-18 characters consisting of numbers, uppercase and lowercase letters") unless user.save
        
        token = generate_multipass_token(user)

        response_shopline_success({ token: token })
      end

      desc "验证手机验证码", {
        skip_authentication: true
      }
      params do
        requires :mobile, type: String, coerce_with: ->(val) { val.to_s.strip }, desc: "手机"
        requires :event, type: String, values: ["shopline_reset_phone", "shopline_reset_email"]
        requires :code, type: String
      end
      get "verify_phone_code" do
        mobile = params[:mobile]
        event = params[:event]

        shopline_check_verification_code!(mobile, params[:code], event)

        # 修改邮箱、手机号时，传过来的手机号是 +614234567890 格式的，需要去掉+，再加上00
        mobile.gsub!('+', "00") unless mobile.start_with?("00")
        # 用户经常会由于习惯把手机号填成6104234567890，参数的mobile值是614234567890，所以查手机号时要查两个手机号
        tmp_mobole = mobile.gsub('614', "6104")
        user = MagicBean::ShoplineUser.find_by(phone: [mobile, tmp_mobole])
        response_shopline_error(I18n.t("error.user.not_found", locale: :en)) unless user

        if event == "shopline_reset_email"
          user.generate_reset_email_token
          user.save
          response_shopline_success({ reset_email_token: user.reset_email_token })
        elsif event == "shopline_reset_phone"
          user.generate_reset_phone_token
          user.save
          response_shopline_success({ reset_phone_token: user.reset_phone_token })
        else
          response_shopline_success
        end
      end

      desc "验证邮箱验证码", {
        skip_authentication: true
      }
      params do
        requires :acct, type: String, coerce_with: ->(val) { val.to_s.strip }, desc: "邮箱"
        requires :event, type: String, values: ["shopline_reset_phone", "shopline_reset_email", "shopline_reset_password"]
        requires :code, type: String
      end
      get "verify_email_code" do
        email = params[:acct]
        event = params[:event]
 
        user = MagicBean::ShoplineUser.find_by(email: email)
        response_shopline_error(I18n.t("error.user.not_found", locale: :en)) unless user
        shopline_check_email_verification_code!(email, params[:code], event)

        if event == "shopline_reset_password"
          user.generate_reset_password_token
          user.save
          response_shopline_success({ reset_password_token: user.reset_password_token })
        elsif event == "shopline_reset_email"
          user.generate_reset_email_token
          user.save
          response_shopline_success({ reset_email_token: user.reset_email_token })
        elsif event == "shopline_reset_phone"
          user.generate_reset_phone_token
          user.save
          response_shopline_success({ reset_phone_token: user.reset_phone_token })
        else
          response_shopline_success
        end    
      end

      desc "修改密码", {
        skip_authentication: true
      }
      params do
        requires :pwd, type: String
        requires :reset_password_token, type: String
      end
      post "password" do
        user = MagicBean::ShoplineUser.find_by(reset_password_token: params[:reset_password_token])
        response_shopline_error(I18n.t("error.user.not_found", locale: :en)) unless user
        response_shopline_error("Password must be 6-18 characters consisting of numbers, uppercase and lowercase letters") unless user.update(password: params[:pwd], reset_password_token: nil)
        
        response_shopline_success
      end

      desc "修改邮箱", {
        skip_authentication: true
      }
      params do
        requires :reset_email_token, type: String
        requires :email, type: String
        requires :code, type: String
      end
      post "email" do
        user = MagicBean::ShoplineUser.find_by(reset_email_token: params[:reset_email_token])
        response_shopline_error(I18n.t("error.user.not_found", locale: :en)) unless user
        shopline_check_email_verification_code!(params[:email], params[:code], :shopline_new_email)

        begin
          MagicBean::ShoplineUser.transaction do
            old_email = user.email
            user.update(email: params[:email], reset_email_token: nil)
            user.update_shopline_user_email(old_email)
          end

          response_shopline_success
        rescue => e
          response_shopline_error(e)
        end            
      end

      desc "修改手机号", {
        skip_authentication: true
      }
      params do
        requires :reset_phone_token, type: String
        requires :mobile, type: String
        requires :smscode, type: String
      end
      post "phone" do
        user = MagicBean::ShoplineUser.find_by(reset_phone_token: params[:reset_phone_token])
        response_shopline_error(I18n.t("error.user.not_found", locale: :en)) unless user
        shopline_check_verification_code!(params[:mobile], params[:smscode], :shopline_new_phone)

        begin
          MagicBean::ShoplineUser.transaction do
            user.update(phone: params[:mobile], reset_phone_token: nil)
            user.update_shopline_user_phone
          end
         
          response_shopline_success
        rescue => e
          response_shopline_error(e)
        end
      end
    end
  end
end
