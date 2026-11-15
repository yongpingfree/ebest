# frozen_string_literal: true

class MarketingSmsJob < ApplicationJob
  queue_as :deliver_sms

  def perform(mobile, message, sms_platform = nil)
    # 目前出现了message为true的情况，未找到原因，在发送短信这里做处理
    return if message.blank? || mobile.blank? || Rails.env.development?

    # 是否不允许发营销短信，是的话跳过
    return if MagicBean::MobileBlacklist.activated?(mobile, :marketing_sms_disabled)

    # 暂时只发AWS的
    if sms_platform == "aws"
      # AWS SNS 营销类短信使用 Promotional 类型(低价高吞吐), 事务类默认 Transactional
      Aws::SMS.send_message(Phony.normalize(mobile), message, Aws::SMS::PROMOTIONAL_SMS_TYPE)
    end
  end
end
