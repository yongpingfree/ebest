# frozen_string_literal: true
module Aliyun
  class SMS
    ALIYUN_CONFIG = Rails.application.credentials.dig(Rails.env.to_sym, :aliyun)

    def self.rpc_client
      @rpc_client ||= RPCClient.new(
        access_key_id: ALIYUN_CONFIG[:access_key_id],
        access_key_secret: ALIYUN_CONFIG[:secret_access_key],
        api_version: "2018-05-01",
        endpoint: "https://#{ALIYUN_CONFIG[:sms_endpoint]}"
      )
    end

    # define send message
    # message_type: OTP：验证码 NOTIFY：短信通知 MKT：推广短信
    # NOTIFY需要先备案，测试OTP都能发送，先使用OTP
    def self.send_message(phone, message, message_type = "OTP")
      rpc_client.request({
        action: "SendMessageToGlobe",
        params: {
          "RegionId": ALIYUN_CONFIG[:sms_region_id],
          "To": phone,
          "Message": message,
          "From": "eBest",
          "Type": message_type
        },
        opts: { method: "POST" }
      })
    end
  end
end
