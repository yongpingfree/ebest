# frozen_string_literal: true

module BeansApp
  class API::V1::Users < ::API
    helpers ::ApiHelpers::MobileHelper
    helpers ::ApiHelpers::EmailHelper

    namespace :user, desc: "用户API" do
      if Rails.env.staging? || Rails.env.development?
        desc "获取用户登录 token", skip_authentication: true, detail: <<-NOTES.strip_heredoc
        ```json
        {
          "access_token": "7f42105510fe33ff62f31084461e0830"
        }
        ```
        NOTES
        params do
          requires :user_id, type: Integer, desc: "用户id"
        end
        get "user_token" do
          user = MagicBean::User.registered.find params[:user_id]
          session[:user_id] = user&.id

          { access_token: JsonWebToken.encode({certificate: user.ebest_platform_unionid || user.id }) }
        end
      end

      desc "通过 code 获取 access_token", {
        detail: <<-NOTES.strip_heredoc
          **旧流程，已废弃**

          获取access_token
          ```json
          {
            access_token: "eyJhbGciOiJIUzI1Ni"
          }
          ```
          NOTES
      }
      params do
        requires :code, type: String, desc: "微信用户的登录凭证(code)"
      end
      post "code_to_token" do
        response = Wechat::Api::code_to_session(params[:code])
        if openid = response["openid"]
          user = MagicBean::User.find_by(open_id: openid)

          unless user
            begin
              user = MagicBean::User.create!(open_id: openid, sign_up_channel: ebest_channel)
            rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation => _
              response_error I18n.t("grape.users.failed_to_auth_wechat_info")
            end
          end

          return response_error(I18n.t("grape.users.account_deleted"), 403) if user.deleted_by_user?

          user.update(session_key: response["session_key"])
          session[:user_id] = user&.id
          { access_token: JsonWebToken.encode({certificate: user.open_id}) }
        else
          response_error response["errmsg"]
        end
      end

      desc "小程序登录；通过 code 获取 access_token", {
        skip_authentication: true,
        detail: <<-NOTES.strip_heredoc
          **旧流程，已废弃**

          获取access_token
          ```json
          {
            access_token: "eyJhbGciOiJIUzI1Ni",
          }
          ```
          NOTES
      }
      params do
        requires :code, type: String, desc: "微信用户的登录凭证(code)"
        requires :encrypted_data, type: String, desc: "完整用户信息的加密数据"
        requires :iv, type: String, desc: "加密算法的初始向量"
        optional :branch_io_campaign, type: String, desc: "活动"
        optional :branch_io_channel, type: String, desc: "渠道"
        optional :branch_io_feature, type: String, desc: "来源，例：qrcode"
        # branch_io_extra_hash，hash类型，grape没法只定义空hash, 前端直接传
      end
      post "token" do
        response = Wechat::Api::code_to_session(params[:code])
        if response["session_key"]
          user_data = ::Wechat::UserData.decrypt!(response["session_key"], params[:encrypted_data], params[:iv])
          unionid = user_data["unionId"]
          begin
            # 兼容测试环境前期未绑定开放平台的情况
            user = MagicBean::User.find_by(open_id: user_data["openId"])
            if user.present?
              return response_error(I18n.t("grape.users.account_deleted"), 403) if user.deleted_by_user?

              mini_user_check_unionid(user, unionid, user_data)
            else
              user = MagicBean::User.find_or_initialize_by(ebest_platform_unionid: unionid)
              user.nickname = user_data["nickName"]
              user.avatar = user_data["avatarUrl"]
              user.gender = user_data["gender"]
              user.open_id = user_data["openId"]
              if user.new_record?
                user.sign_up_channel = ebest_channel
                user.branch_io_campaign = params[:branch_io_campaign]
                user.branch_io_channel = params[:branch_io_channel]
                user.branch_io_feature = params[:branch_io_feature]
                user.branch_io_extra_hash = params[:branch_io_extra_hash]
              end
            end
          rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation => e
            user = MagicBean::User.find_by(ebest_platform_unionid: unionid)
          end

          return response_error(I18n.t("grape.users.account_deleted"), 403) if user.deleted_by_user?

          user.update(session_key: response["session_key"])
          session[:user_id] = user&.id
          {
            access_token: JsonWebToken.encode({certificate: user.ebest_platform_unionid}),
          }
        else
          response_error response["errmsg"]
        end
      end

      # FIXME: 该接口暂时没使用，如果要使用需注意：unionid字段已启用，需改用ebest_platform_unionid
      desc "公众号登录；通过 code 获取 access_token", {
        skip_authentication: true,
        detail: <<-NOTES.strip_heredoc
          获取access_token
          ```json
          {
            access_token: "eyJhbGciOiJIUzI1Ni",
          }
          ```
          NOTES
      }
      params do
        requires :code, type: String, desc: "微信用户的登录凭证(code)"
      end
      post "official_login" do
        sns_info = $wechat_client.get_oauth_access_token(params[:code])
        response_error(sns_info.en_msg, 400) unless sns_info.ok?

        # 获取用户是否关注信息
        userinfo = $wechat_client.user(sns_info.result[:openid])

        response_error(userinfo.en_msg || I18n.t("grape.users.failed_to_auth_wechat_info"), 400) unless userinfo.ok?

        # 获取用户信息
        oauth_userinfo = $wechat_client.get_oauth_userinfo(sns_info.result[:openid], sns_info.result[:access_token])

        response_error(oauth_userinfo.en_msg || I18n.t("grape.users.failed_to_auth_wechat_info"), 400) unless oauth_userinfo.ok?

        unionid = oauth_userinfo.result[:unionid]
        # 生产环境没有 unionid 报错
        response_error(I18n.t("grape.users.failed_to_auth_wechat_info"), 400) if unionid.nil?

        begin
          user = MagicBean::User.find_or_initialize_by(unionid: unionid)
        rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation => e
          user = MagicBean::User.find_by(unionid: unionid)
        end

        return response_error(I18n.t("grape.users.account_deleted"), 403) if user.deleted_by_user?

        user.update(
          nickname: oauth_userinfo.result[:nickname],
          subscribe: userinfo.result[:subscribe] == 1,
          avatar: oauth_userinfo.result[:avatar],
          gender: oauth_userinfo.result[:sex],
          official_open_id: oauth_userinfo.result[:openid]
        )

        {
          access_token: JsonWebToken.encode({certificate: unionid}),
        }
      end

      desc "app微信授权", {
        skip_authentication: true,
        detail: <<-NOTES.strip_heredoc
        获取access_token
        ```json
        {
          access_token: "eyJhbGciOiJIUzI1Ni",
        }
        ```
        NOTES
      }
      params do
        requires :code, type: String, desc: "授权网页回调code"
        optional :branch_io_campaign, type: String, desc: "活动"
        optional :branch_io_channel, type: String, desc: "渠道"
        optional :branch_io_feature, type: String, desc: "来源，例：qrcode"
        # branch_io_extra_hash，hash类型，grape没法只定义空hash, 前端直接传
      end
      post "app_token" do
        sns_info = $mobile_app_client.get_oauth_access_token(params[:code])
        result = sns_info.result
        response_error(I18n.t("grape.users.failed_to_auth_wechat_info")) unless sns_info.ok?
        unionid = result["unionid"]
        access_token =
          if (result["scope"] != "snsapi_userinfo") || unionid.blank?
            nil
          else
            user_info = $mobile_app_client.get_oauth_userinfo(result["openid"], result["access_token"])
            response_error(I18n.t("grape.users.failed_to_auth_wechat_info")) unless user_info.ok?
            user_result = user_info.result
            if current_user
              check_wechat_authorization(user_result)
            else
              user = MagicBean::User.find_or_initialize_by(ebest_platform_unionid: unionid)

              return response_error(I18n.t("grape.users.account_deleted"), 403) if user.deleted_by_user?

              # 如果是新注册的账号，则记录注册平台
              if user.new_record?
                sign_up_channel = ebest_channel
                branch_io_campaign = params[:branch_io_campaign]
                branch_io_channel = params[:branch_io_channel]
                branch_io_feature = params[:branch_io_feature]
                branch_io_extra_hash = params[:branch_io_extra_hash]
              else
                sign_up_channel = user.sign_up_channel
                branch_io_campaign = user.branch_io_campaign
                branch_io_channel = user.branch_io_channel
                branch_io_feature = user.branch_io_feature
                branch_io_extra_hash = user.branch_io_extra_hash
              end

              user.update!(
                nickname: user_result["nickname"],
                avatar: user_result["headimgurl"],
                gender: user_result["sex"],
                app_open_id: user_result["openid"],
                locale: I18n.locale,
                sign_up_channel: sign_up_channel,
                branch_io_campaign: branch_io_campaign,
                branch_io_channel: branch_io_channel,
                branch_io_feature: branch_io_feature,
                branch_io_extra_hash: branch_io_extra_hash
              )
              session[:user_id] = user&.id
              member = user.member
              member.send :assign_newbie_coupon if member
            end
            JsonWebToken.encode({ certificate: unionid })
          end
        {
          access_token: access_token
        }
      end

      desc "手机号码登录", {
        skip_authentication: true,
        detail: <<-NOTES.strip_heredoc
      获取access_token
      ```json
      {
        access_token: "eyJhbGciOiJIUzI1Ni",
        is_new_record: true
      }
      ```
        NOTES
      }
      params do
        requires :mobile, type: String, desc: "手机号码(前端需要传61)"
        requires :code, type: String, desc: "验证码"
        optional :invite_code, type: String, desc: "邀请码"
        optional :h5_register, type: Boolean, desc: "是否为h5注册"
        optional :store_id, type: Integer, desc: "所属门店"
        optional :branch_io_campaign, type: String, desc: "活动"
        optional :branch_io_channel, type: String, desc: "渠道"
        optional :branch_io_feature, type: String, desc: "来源，例：qrcode"
        # branch_io_extra_hash，hash类型，grape没法只定义空hash, 前端直接传
      end
      post "mobile" do
        check_phone_number!(params[:mobile])

        event = params[:h5_register] ? "register_member" : "app_mobile_auth"
        check_verification_code!(params[:mobile], params[:code], event)

        member = MagicBean::Member.find_or_initialize_by(mobile: params[:mobile])

        is_new_record = member.new_record?
        response_error(I18n.t("grape.users.already_a_member")) if params[:h5_register] && !is_new_record

        user = if is_new_record
                 sign_up_channel = params[:h5_register] ? "app" : ebest_channel
                 member.user = MagicBean::User.new(
                   gender: :unknow,
                   nickname: "手机用户#{MagicBean::User.maximum(:id).next}",
                   selected_store_id: params[:store_id].presence || current_store_id,
                   locale: I18n.locale,
                   sign_up_channel: sign_up_channel,
                   branch_io_campaign: params[:branch_io_campaign],
                   branch_io_channel: params[:branch_io_channel],
                   branch_io_feature: params[:branch_io_feature],
                   branch_io_extra_hash: params[:branch_io_extra_hash]
                 )
                 invited_member = MagicBean::Member.find_by(invite_code: params[:invite_code])
                 response_error(I18n.t("grape.users.provide_correct_code")) if params[:invite_code].present? && invited_member.blank?
                 member.inviter = invited_member
                 member.channel = sign_up_channel
                 member.save ? member.user : nil
               else
                 member.send :assign_newbie_coupon
                 member.user
               end

        return response_error(I18n.t("grape.users.failed_to_login"), 403) if user.nil?
        return response_error(I18n.t("grape.users.account_deleted"), 403) if user.deleted_by_user?

        if is_new_record && ebest_channel == "web"
          # 英文网站目前没有切换语系功能，默认为英文
          user.update_column(:locale, :en)
        end

        session[:user_id] = user.id
        { access_token: JsonWebToken.encode({ certificate: user.id }), is_new_record: is_new_record }
      end

      desc "密码登录", {
        skip_authentication: true,
        detail: <<-NOTES.strip_heredoc
      获取access_token
      ```json
      {
        access_token: "eyJhbGciOiJIUzI1Ni",
        is_new_record: true
      }
      ```
        NOTES
      }
      params do
        requires :mobile, type: String, desc: "手机号码(前端需要传61)"
        requires :password, type: String, desc: "密码"
      end
      post "password" do
        params.map { |k, v| v.strip! }
        check_phone_number!(params[:mobile])
        member = MagicBean::Member.find_by(mobile: params[:mobile])

        response_error(I18n.t("error.user.not_found")) unless member

        # 10分钟内只能尝试登录5次
        redis = Rails.cache.redis
        login_key = "user-#{params[:mobile]}-login-times"
        login_times = redis.get(login_key).to_i
        if login_times.positive?
          response_error(I18n.t("error.user.login_more_than_times")) if login_times >= MagicBean::Member::MAX_LOGIN_TRY
          redis.incr(login_key)
        else
          redis.set(login_key, 1, ex: 10.minutes)
        end

        user = member.user

        if user.has_password? && user.try(:authenticate, params[:password])
          redis.del(login_key)
          session[:user_id] = user.id
          { access_token: JsonWebToken.encode({ certificate: user.id }) }
        else
          response_error(I18n.t("error.user.incorrect_password"))
        end
      end

      desc "重置密码", {
        success: ::BeansApp::API::Entities::SuccessfulResult,
        skip_authentication: true
      }
      params do
        optional :mobile, type: String, desc: "手机号码(前端需要传61)，忘记密码才需要传"
        optional :code, type: String, desc: "验证码，忘记密码才需要传"
        optional :old_password, type: String, desc: "原密码（修改密码且已设置过密码时需要传）"
        requires :password, type: String, desc: "新密码"
        requires :password_confirmation, type: String, desc: "密码确认"
      end
      put "password" do
        if params[:mobile]
          verification_code = MagicBean::VerificationCode.build_app_reset_password_object(params[:mobile] || "")
          response_error(I18n.t("error.mobile.invalid_code")) unless verification_code.verify(params[:code] || "")

          user = MagicBean::Member.find_by(mobile: params[:mobile])&.user
          response_error(I18n.t("error.user.not_found")) unless user
        else
          user = current_user
          response_error(I18n.t("error.user.login_first")) unless user

          if user.has_password? && !user.try(:authenticate, params[:old_password])
            response_error(I18n.t("error.user.old_password_not_correct"))
          end
        end

        if user.update(raw_parameters(params).permit(:password, :password_confirmation))

          verification_code.code = nil if params[:mobile]

          response_success
        else
          response_record_error(user)
        end
      end

      desc "返回个人信息", {
        success: ::BeansApp::API::Entities::User
      }
      get do
        session[:user_id] = current_user&.id
        present current_user,
                with: ::BeansApp::API::Entities::User,
                with_user_account: true
      end

      desc "修改个人资料", {
        success: ::BeansApp::API::Entities::User
      }
      params do
        optional :nickname, as: :origin_nickname, type: String, desc: "微信昵称"
        optional :gender, as: :origin_gender, type: Integer, values: [0, 1, 2, 3], desc: "性别 0：未知、1：男、2：女、3：不愿意透露"
        optional :avatar, as: :origin_avatar, type: String, desc: "头像url"
        optional :locale, type: String, desc: "语言设置"
        optional :member_attributes, type: JSON do
          requires :id
          requires :birthday
          optional :email
          optional :code
          optional :receive_activity_email, type: Boolean, desc: "是否接收活动优惠邮件"
          optional :first_name, type: String, desc: "名字"
          optional :last_name, type: String, desc: "姓氏"
        end
      end
      put do
        # 如果填写了email, 且邮箱更新的话，就要校验code
        member = current_user.member

        if params[:member_attributes].present? && member
          email = params[:member_attributes][:email]&.strip
          code = params[:member_attributes][:code]&.strip

          if email.present? && email != member.email
            check_email!(email, :bind_member)
            check_email_verification_code!(email, code, :bind_member)
            params[:member_attributes][:email_verified_at] = Time.current unless member.email_confirmed?
          elsif code.present?
            check_email_verification_code!(email, code, :bind_member)
            params[:member_attributes][:email_verified_at] = Time.current
          end
        end

        standard_update(current_user, user_params, ::BeansApp::API::Entities::User)
      end

      desc "绑定手机号", {
        success: ::BeansApp::API::Entities::User
      }
      params do
        requires :encrypted_data, type: String, desc: "加密数据"
        requires :iv, type: String, desc: "初始向量"
      end
      post "bind_mobile" do
        user = current_user

        begin
          user_data = ::Wechat::UserData.decrypt!(user.session_key, params[:encrypted_data], params[:iv])
        rescue StandardError => e
          response_error e.message, 401 # 用户 session key 可能为空或过期，需要返回 401 重新刷新 session key
        end

        if user.update(mobile: user_data["phoneNumber"])
          present user, with: ::BeansApp::API::Entities::User, with_user_account: true
        else
          response_record_error(user)
        end
      end

      desc "获取最后一次订单地址", {
        success: ::BeansApp::API::Entities::Address
      }
      get "last_order_address" do
        user = current_user
        order = user.orders.where.not(paid_at: nil).first
        if order
          {
            id: order.receiver_properties[:id],
            city_name: order.receiver_city_name,
            postal_code: order.receiver_postal_code
          }
        end
      end

      desc "注销（删除）账号", {
        success: API::Entities::SuccessfulResult
      }
      params do
        optional :mobile, type: String, desc: "手机号码(前端需要传61)，非会员用户不需要传"
      end
      delete do
        if current_user.member && current_user.member_mobile != params[:mobile]
          return response_error(I18n.t("grape.users.invalid_mobile"))
        end

        if current_user.delete_account
          session.delete(:user_id)
          response_success
        else
          response_record_error(current_user)
        end
      end

      desc "获取邮箱验证码", {
        detail: { code: 200, message: "OK",
                  result: { verification_code: "only development" }
                }.to_s,
        skip_authentication: true
      }
      params do
        requires :email, type: String, coerce_with: ->(val) { val.to_s.strip }, desc: "邮箱"
        requires :event, type: String, values: ["overseas_student_auth", "bind_member", "login"]
      end
      get "email_verification_code" do
        email = params[:email].to_s.strip
        event = params[:event]

        check_email!(email, event)

        if event == "login" && !MagicBean::Member.exists?(email: email)
          # 登录没注册过的邮箱不发送验证码
          return response_success(I18n.t("grape.members.code_sent"))
        end

        vc = MagicBean::EmailVerificationCode.new(email, event)

        if vc.code.present? && !vc.can_send_again?
          response_error(I18n.t("error.mobile.code_aleady_sent"))
        else
          vc.send_code

          result = {}
          result[:verification_code] = vc.code if Rails.env.development?

          response_success(I18n.t("grape.members.code_sent"), result: result)
        end
      end

      desc "用户注册（email + mobile）", {
        skip_authentication: true,
        detail: <<-NOTES.strip_heredoc
        返回用户的 access_token

        ```json
        {
          access_token: "eyJhbGciOiJIUzI1Ni"
        }
        ```
        NOTES
      }
      params do
        requires :mobile, type: String, desc: "手机号码(前端需要传61)"
        requires :email, type: String, coerce_with: ->(val) { val.to_s.strip },  desc: "邮箱"
        requires :code, type: String, desc: "手机验证码"
        requires :password, type: String, desc: "密码，长度至少8位，包含大小写字母、数字和标点符号"
        requires :password_confirmation, type: String, desc: "密码确认"
        optional :invite_code, type: String, desc: "邀请码"
        optional :receive_activity_email, type: Boolean, desc: "是否接收活动优惠邮件"
        optional :first_name, type: String, desc: "名字"
        optional :last_name, type: String, desc: "姓氏"
        optional :branch_io_campaign, type: String, desc: "活动"
        optional :branch_io_channel, type: String, desc: "渠道"
        optional :branch_io_feature, type: String, desc: "来源，例：qrcode"
        # branch_io_extra_hash，hash类型，grape没法只定义空hash, 前端直接传
      end
      post "sign_up" do
        check_phone_number!(params[:mobile])
        check_verification_code!(params[:mobile], params[:code], :register_member)

        if MagicBean::Member.where("mobile = :mobile OR email = :email", mobile: params[:mobile], email: params[:email]).exists?
          response_error(I18n.t("grape.users.already_a_member"))
        end

        invited_member = nil
        if params[:invite_code].present?
          invited_member = MagicBean::Member.find_by(invite_code: params[:invite_code])
          response_error(I18n.t("grape.users.provide_correct_code")) if invited_member.nil?
        end

        member = MagicBean::Member.new(member_params)
        member.inviter = invited_member
        member.channel = ebest_channel
        member.build_user(
          password: params[:password],
          password_confirmation: params[:password_confirmation],
          gender: :unknow,
          nickname: "User#{params[:mobile].last(4)}",
          selected_store_id: params[:store_id].presence || current_store_id,
          locale: get_locale,
          sign_up_channel: ebest_channel,
          branch_io_campaign: params[:branch_io_campaign],
          branch_io_channel: params[:branch_io_channel],
          branch_io_feature: params[:branch_io_feature],
          branch_io_extra_hash: params[:branch_io_extra_hash]
        )

        if member.save
          session[:user_id] = member.user_id
          { access_token: JsonWebToken.encode({ certificate: member.user_id }) }
        else
          response_record_error(member)
        end
      end

      # 简化流程后的用户注册
      desc "用户注册（只用mobile）", {
        skip_authentication: true,
        detail: <<-NOTES.strip_heredoc
        返回用户的 access_token

        ```json
        {
          access_token: "eyJhbGciOiJIUzI1Ni"
        }
        ```
        NOTES
      }
      params do
        requires :mobile, type: String, desc: "手机号码(前端需要传61)"
        requires :code, type: String, desc: "手机验证码"
        optional :invite_code, type: String, desc: "邀请码"
        optional :branch_io_campaign, type: String, desc: "活动"
        optional :branch_io_channel, type: String, desc: "渠道"
        optional :branch_io_feature, type: String, desc: "来源，例：qrcode"
        # branch_io_extra_hash，hash类型，grape没法只定义空hash, 前端直接传
      end
      post "simple_sign_up" do
        check_phone_number!(params[:mobile])
        check_verification_code!(params[:mobile], params[:code], :register_member)

        response_error(I18n.t("grape.users.already_a_member")) if MagicBean::Member.where(mobile: params[:mobile]).exists?
          
        invited_member = nil
        if params[:invite_code].present?
          invited_member = MagicBean::Member.find_by(invite_code: params[:invite_code])
          response_error(I18n.t("grape.users.provide_correct_code")) if invited_member.nil?
        end

        member = MagicBean::Member.new(member_params)
        member.inviter = invited_member
        member.channel = ebest_channel
        member.build_user(
          gender: :unknow,
          nickname: "User#{params[:mobile].last(4)}",
          selected_store_id: params[:store_id].presence || current_store_id,
          locale: get_locale,
          sign_up_channel: ebest_channel,
          branch_io_campaign: params[:branch_io_campaign],
          branch_io_channel: params[:branch_io_channel],
          branch_io_feature: params[:branch_io_feature],
          branch_io_extra_hash: params[:branch_io_extra_hash]
        )

        if member.save
          session[:user_id] = member.user_id
          { access_token: JsonWebToken.encode({ certificate: member.user_id }) }
        else
          response_record_error(member)
        end
      end

      # 根据用户手机号，返回用户是否是新用户，以及用户是否设置了密码
      desc "用户是否是新用户", {
        skip_authentication: true,
        detail: <<-NOTES.strip_heredoc
        ```json
        {
          is_new_record: true,
          has_password: true
        }
        ```
        NOTES
      }
      params do
        requires :mobile, type: String, desc: "手机号码(前端需要传61)"
      end

      get "check_user" do
        check_phone_number!(params[:mobile])
        member = MagicBean::Member.find_by(mobile: params[:mobile])
        if member
          {
            is_new_record: false,
            has_password: member.user.has_password?
          }
        else
          {
            is_new_record: true,
            has_password: false,
            total_users_count: MagicBean::User.count + 26001 # 注册的时候会显示用户是排名第几位，总数会再加26000
          }
        end
      end

      desc "绑定指纹", {
        success: ::BeansApp::API::Entities::User
      }
      params do
        requires :signature, type: String, desc: "指纹签名"
      end
      post "bind_fingerprint" do
        exist_user = MagicBean::User.fingerprint_signatures_contains_any(params[:signature])
        if exist_user.present? && exist_user != current_user
          response_error(I18n.t("grape.users.fingerprint_already_bind"))
        else
          # 先减再加，保证最新绑定的指纹排在最后
          fingerprint_signatures = current_user.fingerprint_signatures - [params[:signature]] + [params[:signature]]
          # 超过指纹限制个数，删除最早的指纹
          fingerprint_signatures.shift if fingerprint_signatures.size > MagicBean::User::MAX_FINGERPRINT_COUNT
          current_user.update(fingerprint_signatures: fingerprint_signatures)
          present current_user, with: ::BeansApp::API::Entities::User, with_user_account: true
        end
      end

      desc "删除指纹", {
        success: ::BeansApp::API::Entities::User
      }
      params do
        requires :signature, type: String, desc: "指纹签名"
      end
      delete "fingerprint" do
        fingerprint_signatures = (current_user.fingerprint_signatures - [params[:signature]]).uniq
        current_user.update(fingerprint_signatures: params[:signature])
        response_success
      end
    end
  end
end
