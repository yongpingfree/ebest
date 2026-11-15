# frozen_string_literal: true

# 通用 Excel 导入数据结果通知 mailer
class ExcelImportMailer < ApplicationMailer
  # 给管理员发送批量通知失败结果
  def notify_admin_user(email, subject, result)
    @result = result
    mail to: email, subject: subject
  end
end
