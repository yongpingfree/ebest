# frozen_string_literal: true

class CustomListMailer < ApplicationMailer
  def notify_admin_user(email, result)
    @result = result
    mail to: email, subject: "自定义商品列表【#{@result[:title]}】导入结果"
  end
end
