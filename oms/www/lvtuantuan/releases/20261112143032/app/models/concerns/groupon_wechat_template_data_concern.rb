# frozen_string_literal: true

module GrouponWechatTemplateDataConcern
  extend ActiveSupport::Concern

  def groupon_finished_template_data
    {
      "thing1": {
        value: groupon_activity.item_title
      },
      "amount5": {
        value: "￥#{payment_in_yuan}"
      },
      "date2": {
        value: Time.current.strftime("%Y年%m月%d日 %H:%M")
      },
      "thing4": {
        value: "拼团已经成功啦。赶紧去享受吧！"
      }
    }
  end

  def groupon_canceled_template_data
    {
      "thing1": {
        value: groupon_activity.item_title
      },
      "amount2": {
        value: "￥#{payment_in_yuan}"
      },
      "thing7": {
        value: "人数不足，拼团失败"
      },
      "thing6": {
        value: "拼团失败，将按原路退款"
      }
    }
  end
end
