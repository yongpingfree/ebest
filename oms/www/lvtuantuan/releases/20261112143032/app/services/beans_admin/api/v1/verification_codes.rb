# frozen_string_literal: true

module BeansAdmin
  class API::V1::VerificationCodes < ::API

    namespace :verification_codes, desc: "验证码" do
      desc "获取万能验证码", detail: <<-NOTES.strip_heredoc
      remaining_time 单位: 分钟
      ```json
      { universal_code: 23790, remaining_time: 20() }
      ```
      NOTES
      get "universal_code" do
        universal_code = Rails.cache.fetch(MagicBean::VerificationCode::UNIVERSAL_CODE_KEY)
        remaining_time = 0
        if universal_code
          remaining_time = Rails.cache.redis.ttl(MagicBean::VerificationCode::UNIVERSAL_CODE_KEY) / 60 # ttl return seconds
        else
          chars = ("0".."9").to_a
          new_code = 6.times.map { chars.sample }.join
          Rails.cache.write(MagicBean::VerificationCode::UNIVERSAL_CODE_KEY, new_code, expires_in: 20.minutes)
          remaining_time = 20
          universal_code = new_code
        end
        { universal_code: universal_code, remaining_time: remaining_time }
      end
    end
  end
end
