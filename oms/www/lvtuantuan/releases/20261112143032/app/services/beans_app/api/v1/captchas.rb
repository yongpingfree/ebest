# frozen_string_literal: true

module BeansApp
  class API::V1::Captchas < ::API
    helpers ::ApiHelpers::MobileHelper

    namespace :captchas do
      desc "获取图形验证码", {
        detail: { code: 200, message: "OK",
                  result: { captcha_key: "captcha key", captcha_image: "data:image/gif;base64,..." }
                }.to_s,
        skip_authentication: true
      }
      params do
        requires :mobile, type: String, desc: "手机号码"
        requires :event, type: String, desc: "事件类型", values: ["register_member", "reset_mobile", "app_mobile_auth", "app_reset_password", "login"]
      end
      get do
        check_phone_number!(params[:mobile])
        captcha = MagicBean::Captcha.generate(mobile: params[:mobile], event: params[:event])

        response_success("OK", result: {
          captcha_key: captcha.key,
          captcha_image: captcha.image_data_uri
        })
      end
    end
  end
end
