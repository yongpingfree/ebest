# frozen_string_literal: true

module BeansApp
  class API::V1::Members < ::API

    helpers ::ApiHelpers::MobileHelper
    helpers ::ApiHelpers::EmailHelper

    namespace :members do
      helpers do
        def resource
          @resource ||= current_user.member
        end

        def permitted_params
          [:user_id, :mobile, :birthday, :channel, :inviter_id, :email]
        end
      end

      desc "发送验证码", {
        detail: { code: 200, message: "OK",
                  result: { verification_code: "only development" }
                }.to_s,
        skip_authentication: true
      }
      params do
        requires :mobile, type: String, desc: "手机号码"
        requires :event, type: String, desc: "事件类型", values: ["register_member", "reset_mobile", "app_mobile_auth", "app_reset_password", "login"]
        requires :captcha_key, type: String, desc: "图形验证码 key"
        requires :captcha_code, type: String, desc: "图形验证码"
      end
      get "verification_code" do
        mobile = params[:mobile]
        event = params[:event]

        response_error(I18n.t("error.common.invalid_captcha")) unless MagicBean::Captcha.verify(
          params[:captcha_key],
          params[:captcha_code],
          mobile: mobile,
          event: event
        )
        
        check_phone_number!(params[:mobile])

        if event == "login" && !MagicBean::Member.exists?(mobile: mobile)
          # 登录没注册过的手机号不发送验证码
          return response_success(I18n.t("grape.members.code_sent"))
        end

        vc = MagicBean::VerificationCode.new(mobile, event)

        if vc.code.present? && !vc.can_send_again?
          response_error(I18n.t("error.mobile.code_aleady_sent"))
        else
          vc.send_code

          result = {}
          result[:verification_code] = vc.code if Rails.env.development?

          response_success(I18n.t("error.mobile.code_aleady_sent"), result: result)
        end
      end

      desc "注册会员", {
        success: API::Entities::Member
      }
      params do
        requires :mobile, type: String, desc: "手机号码"
        optional :code, type: String, desc: "验证码"
        requires :type, type: String, values: ["wechat", "code"], desc: "验证方式"
        optional :birthday, type: DateTime, desc: "生日"
        optional :inviter_code, type: String, desc: "邀请人的邀请码"
      end
      post do
        if current_user.member
          response_error(I18n.t("grape.users.already_a_member"))
        else
          check_phone_number!(params[:mobile])
          if params[:type].eql?("code")
            check_verification_code!(params[:mobile], params[:code], "register_member")
          end

          begin
            exist_member = MagicBean::Member.find_by(mobile: params[:mobile])
            if exist_member
              check_member_mobile_authorization(exist_member, ebest_channel == "app")
              present exist_member, with: API::Entities::Member
            else
              inviter = MagicBean::Member.find_by(invite_code: params[:inviter_code])
              response_error(I18n.t("grape.users.provide_correct_code")) if params[:inviter_code].present? && inviter.blank?
              member = current_user.build_member(resource_params.merge({inviter_id: inviter&.id, channel: ebest_channel}))
              standard_save(member, API::Entities::Member)
            end
          rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation => e
            response_error(I18n.t("grape.users.already_a_member"))
          end
        end
      end

      desc "修改会员信息", {
        success: API::Entities::Member
      }
      params do
        optional :mobile, type: String, desc: "手机号码"
        optional :code, type: String, desc: "验证码"
        optional :new_mobile, type: String, desc: "新手机号码"
        optional :new_code, type: String, desc: "新手机的验证码"
        optional :birthday, type: String, desc: "生日"
        optional :inviter_code, type: String, desc: "邀请人的邀请码"
        all_or_none_of :mobile, :code, :new_mobile, :new_code
      end
      put do
        mobile = params[:mobile]
        if resource
          if mobile
            check_phone_number!(mobile)
            check_verification_code!(mobile, params[:code], "reset_mobile")

            # 绑定新手机
            if params[:new_mobile].present? && params[:new_code].present?
              # 验证旧手机为此会员的
              error!({ message: I18n.t("error.mobile.invalid_original_number") }, 400) if resource.mobile != mobile
              new_mobile= params[:new_mobile]
              check_phone_number!(new_mobile)
              check_verification_code!(new_mobile, params[:new_code], "reset_mobile")
              params[:mobile] = params[:new_mobile]
            end
          end

          if params[:inviter_code]
            response_error(I18n.t("grape.users.already_invited")) if resource.inviter_id?
            inviter = MagicBean::Member.find_by(invite_code: params[:inviter_code])
            response_error(I18n.t("grape.users.provide_correct_code")) unless inviter
            params[:inviter_id] = inviter.id
          end

          resource.update(resource_params)
          standard_save(resource, API::Entities::Member)
        else
          response_error(I18n.t("grape.users.not_registered_member"))
        end
      end

      desc "绑定邮箱", {
        success: API::Entities::Member
      }
      params do
        requires :email, type: String, coerce_with: ->(val) { val.to_s.strip }, desc: "邮箱"
        requires :code, type: String, desc: "验证码"
        requires :receive_activity_email, type: Boolean, desc: "是否接收活动优惠邮件"
      end
      put "bind_email" do
        if resource
          check_email!(params[:email], :bind_member)
          check_email_verification_code!(params[:email], params[:code], :bind_member)
          resource.email = params[:email]
          resource.receive_activity_email = params[:receive_activity_email]
          standard_save(resource, API::Entities::Member)
        else
          response_error(I18n.t("grape.users.not_registered_member"))
        end
      end

      desc "积分记录", {
        success: API::Entities::IntegralRecord,
        is_array: true
      }
      paginate
      get "integral_records" do
        response_error(I18n.t("grape.users.not_registered_member")) if resource.nil?
        authorize! :read, MagicBean::IntegralRecord
        present paginate(resource.integral_records.show.app.order("id desc")), with: API::Entities::IntegralRecord
      end

      desc "获取手机号码", {
        success: ::BeansApp::API::Entities::User
      }
      params do
        requires :encrypted_data, type: String, desc: "加密数据"
        requires :iv, type: String, desc: "初始向量"
      end
      post "wechat_mobile" do
        user = current_user
        begin
          user_data = ::Wechat::UserData.decrypt!(user.session_key, params[:encrypted_data], params[:iv])
        rescue StandardError => e
          response_error e.message, 401 # 用户 session key 可能为空或过期，需要返回 401 重新刷新 session key
        end
        user_data
      end

      desc "邀请券记录", {
        success: API::Entities::InvitedCoupon,
        is_array: true
      }
      paginate
      get "invited_coupons" do
        response_error(I18n.t("grape.users.not_registered_member")) if resource.nil?
        authorize! :read, MagicBean::Coupon
        # 被邀请人下单完成后发给邀请人的券也需要展示出来
        present paginate(current_user.coupons.where.not(invitee_id: nil).includes([:coupon_template, :invitee]).order("created_at desc")), with: API::Entities::InvitedCoupon
      end
    end
  end
end
