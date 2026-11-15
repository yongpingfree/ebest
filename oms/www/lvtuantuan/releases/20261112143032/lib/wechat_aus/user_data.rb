# frozen_string_literal: true

module WechatAus
  class UserData
    WECHAT_CONFIG = Rails.application.credentials.dig(Rails.env.to_sym, :wechat_aus)

    APP_ID = WECHAT_CONFIG[:app_id]
    # [用户数据的签名验证和加解密文档](https://mp.weixin.qq.com/debug/wxadoc/dev/api/signature.html)
    def self.decrypt!(session_key, encrypted_data, iv)
      begin
        cipher = OpenSSL::Cipher::AES.new 128, :CBC
        cipher.decrypt
        cipher.padding = 0
        cipher.key = Base64.decode64(session_key)
        cipher.iv  = Base64.decode64(iv)
        data = cipher.update(Base64.decode64(encrypted_data)) << cipher.final
        result = JSON.parse data[0...-data.last.ord]
      rescue StandardError => e
        raise "微信解析数据错误"
      end

      raise "微信解析数据错误" if result.dig("watermark", "appid") != APP_ID

      result
    end
  end
end
