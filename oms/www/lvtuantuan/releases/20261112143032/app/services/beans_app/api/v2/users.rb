# frozen_string_literal: true

module BeansApp
  class API::V2::Users < ::API
    namespace :user, desc: "用户API" do
      desc "小程序登录；通过 code 获取 access_token（已废弃）", {
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
      end
      post "token" do
        response = WechatAus::Api::code_to_session(params[:code])
        if response["session_key"]
          user_data = ::WechatAus::UserData.decrypt!(response["session_key"], params[:encrypted_data], params[:iv])
          unionid = user_data["unionId"]
          user = MagicBean::User.find_or_create_by(ebest_platform_unionid: unionid)

          return response_error(I18n.t("grape.users.account_deleted"), 403) if user.deleted_by_user?

          user.nickname = user_data["nickName"]
          user.avatar = user_data["avatarUrl"]
          user.gender = user_data["gender"]
          user.aus_mp_open_id = user_data["openId"]
          user.aus_mp_session_key = response["session_key"]
          if user.save
            session[:user_id] = user&.id
            {
              access_token: JsonWebToken.encode({certificate: user.ebest_platform_unionid})
            }
          else
            response_record_error(user)
          end
        else
          response_error response["errmsg"]
        end
      end
    end
  end
end
