# frozen_string_literal: true

class AppTextMessageMailer < ApplicationMailer
  # 给管理员发送批量通知失败结果
  def notify_admin_user(email, failure_records, processed_count = 0)
    @failure_records = failure_records
    @processed_count = processed_count
    mail to: email, subject: "消息批量发送结果通知"
  end
end
