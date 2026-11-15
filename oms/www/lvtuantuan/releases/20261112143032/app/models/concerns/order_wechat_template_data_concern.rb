# frozen_string_literal: true

module OrderWechatTemplateDataConcern
  extend ActiveSupport::Concern

  def template_message_params(type)
    {
      touser: user.open_id,
      page: page_path(type),
      type: type,
      data: send("#{type}_template_data"),
      targetable_type: "MagicBean::Order",
      targetable_id: self.id,
      user_id: user.id
    }
  end

  def mini_program_path
    "pages/orders/detail/detail?id=#{id}"
  end

  def app_path

  end

  def page_path(type)
    if %w(groupon_finished groupon_canceled).include?(type)
      groupon.mini_program_path
    else
      mini_program_path
    end
  end

# 订单号 11889
  # 退款编号 400120171203116
  # 商品名称 保健护肤品
  # 退款金额 20元
  # 退款说明 退款已经原路返回, 其中 20 元将退回到余额
  def refund_template_data
    {
      "character_string2": {
        value: no
      },
      "thing5": {
        value: order_items.pluck(:title).join(",")
      },
      "amount3": {
        value: "#{payment_in_yuan}元"
      },
      "thing1": {
        value: "审核通过，退款中"
      },
      "thing6": {
        value: "退款已经原路返回"
      }
    }
  end

  # 订单号 287368726886
  # 商品清单 商品A等商品
  # 发货时间 2016年8月9日
  # 快递公司 TIT造舰快递
  # 快递单号 1002598019811
  def delivery_template_data
    {
      "character_string7": {
        value: no
      },
      "thing5": {
        value: order_items.pluck(:title).join(",")
      },
      "date6": {
        value: delivered_at.strftime("%Y年%m月%d日 %H:%M")
      },
      "character_string3": {
        value: logistic_nos.any? ? logistic_nos.join(",") : "无"
      },
      "thing4": {
        value: logistics.first&.company
      }
    }
  end
end
