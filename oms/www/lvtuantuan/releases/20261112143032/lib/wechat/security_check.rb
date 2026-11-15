# frozen_string_literal: true

require "rest-client"

module Wechat
  class SecurityCheck

    OK_CODE = 0
    RISKY_CODE = 87014
    RETRY_TIMES = 3
    BASE_URI = "https://api.weixin.qq.com/wxa"

    @@logger = ::Logger.new("./log/wx_app_api.log")

    def valid?
      response = check
      if response
        result = JSON.parse(response)
        errMsg = ""
        case result["errcode"]
        when OK_CODE
          return true
        when RISKY_CODE
          errMsg = "您提交的内容含有违法违规内容，请修改后重新提交！"
        else
          errMsg = "服务器繁忙，请稍候尝试！"
        end
        self.instance_variable_set(:@error, errMsg)
        return false
      end
    end

    def post(url, option)
      tries = RETRY_TIMES
      path = "#{BASE_URI}#{url}?access_token=#{access_token}"
      @@logger.debug("request: url: #{path}, option: #{option}")
      error_response = { errcode: -2000 }.to_json
      response =  begin
                    RestClient.post(path, option, timeout: 5)
                  rescue RestClient::ExceptionWithResponse => e
                    @@logger.debug("request: url: #{path}, option: #{option}, ExceptionWithResponse: #{e}")
                    (tries -= 1) > 0 ? retry : error_response
                  rescue => e
                    @@logger.debug("Exception: #{e}")
                    error_response
                  end
      @@logger.debug("response: #{response}")
      response
    end

    private

    def access_token
      ::Wechat::AccessToken.get_mini_program_access_token
    end
  end
end
