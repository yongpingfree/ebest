# frozen_string_literal: true

module IntegralRecordWechatTemplateDataConcern
  extend ActiveSupport::Concern

  def integral_increased_template_data
    {
      "number9": {
        value: integral
      },
      "date5": {
        value: Time.current.strftime("%Y年%m月%d日 %H:%M")
      },
      "thing11": {
        value: template_message_remark
      }
    }
  end

  def mini_program_path
    "pages/vip/list/list".freeze
  end

  def app_path

  end

  def template_message_params(user, type)
    {
      touser: user.open_id,
      page: mini_program_path,
      type: type,
      data: send("#{type}_template_data"),
      targetable_type: self.targetable_type,
      targetable_id: self.targetable_id,
      user_id: user.id
    }
  end

  def template_message_remark
    case kind
    when "sign_up"
      "欢迎成为eBest会员"
    when "order_finished"
      "订单消费奖励"
    end
  end
end
