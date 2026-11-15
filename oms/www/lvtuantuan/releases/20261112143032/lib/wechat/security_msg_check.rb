# frozen_string_literal: true

# 测试用例
# msg = Wechat::SecurityMsgCheck.new("特3456书yuuo莞6543李zxcz蒜7782法fgnv级")
# msg.valid?
module Wechat
  class SecurityMsgCheck < SecurityCheck

    def initialize(content)
      @content = content
      @error = nil
    end

    def check
      msg_sec_check
    end

    private
    def msg_sec_check
      post(
        "/msg_sec_check",
        {
          content: @content
        }.to_json
      )
    end
  end
end
