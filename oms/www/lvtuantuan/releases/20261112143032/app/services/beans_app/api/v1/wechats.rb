# frozen_string_literal: true

module BeansApp
  class API::V1::Wechats < ::API
    namespace :wechat, desc: "微信 API" do
      desc "获取access token", skip_authentication: true
      get "access_token" do
        check_api_authorization_token!

        { access_token: ::Wechat::AccessToken.get_mini_program_access_token }
      end

      desc "获取小程序二维码", {
        skip_authentication: true,
        detail: <<-NOTES.strip_heredoc
          获取小程序二维码

          ```json
          {
            "path": "public/uploads/qrcodes/39dcc64196d11a49b1fd5183cf467f45.jpg"
          }
          ```
        NOTES
      }
      params do
        requires :path, type: String, desc: "小程序页面"
        requires :scene, type: String, desc: "小程序页面参数"
        optional :width, type: Integer, desc: "二维码宽度"
        optional :binary, type: Boolean, desc: "是获取binary还是返回图片路径"
        optional :is_hyaline, type: Boolean, desc: "是否需要透明底色"
      end
      get "mini_program_qrcode" do

        result = ::Wechat::Api.get_mini_program_qrcode(
          params[:scene],
          params[:path],
          params[:width],
          params[:binary],
          params[:is_hyaline]
        )

        if result[:status] == "success"
          if params[:binary]
            content_type "application/octet-stream;charset=ASCII-8BIT"
            env["api.format"] = :binary
            result[:file]
          else
            { path: result[:file] }
          end
        else
          response_error result[:message]
        end
      end

      desc "小程序静默授权，通过 code 获取 access_token", {
        skip_authentication: true,
        detail: <<-NOTES.strip_heredoc
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

        if unionid = response["unionid"]
          begin
            user = MagicBean::User.find_or_create_by(ebest_platform_unionid: unionid)
          rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation => e
            response_error I18n.t("grape.users.failed_to_auth_wechat_info")
          end

          return response_error(I18n.t("grape.users.account_deleted"), 403) if user.deleted_by_user?

          user.update(session_key: response["session_key"], open_id: response["openid"])
          session[:user_id] = user&.id

          { access_token: JsonWebToken.encode({ certificate: user.ebest_platform_unionid }) }
        else
          response_error response["errmsg"]
        end
      end

      desc "小程序 SNS 授权", {
        detail: <<-NOTES.strip_heredoc
          更新前需先完成静默授权（`code_to_token` 接口）
          NOTES
      }
      params do
        requires :encrypted_data, type: String, desc: "完整用户信息的加密数据"
        requires :iv, type: String, desc: "加密算法的初始向量"
      end
      post "sns_authorization" do
        user_data = ::Wechat::UserData.decrypt!(current_user.session_key, params[:encrypted_data], params[:iv])
        current_user.nickname = user_data["nickName"]
        current_user.avatar = user_data["avatarUrl"]
        current_user.gender = user_data["gender"]

        if current_user.save
          present current_user, with: ::BeansApp::API::Entities::User
        else
          response_record_error(current_user)
        end
      end
    end
  end
end
