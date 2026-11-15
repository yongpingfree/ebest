# frozen_string_literal: true
class SendSubscribeMessagesJob < ApplicationJob
  queue_as :wechat

  def perform(options)
    options[:template_id] = Wechat::TemplateMessage.get_template_id(options.delete(:type))
    record = MagicBean::SubscribeRecord.where(
      targetable_type: [options.delete(:targetable_type), nil],
      targetable_id: [options.delete(:targetable_id), nil],
      user_id: options.delete(:user_id),
      template_id: options[:template_id]
    ).order("targetable_id IS NULL").first

    if record
      Wechat::Api.send_subscribe_template(options)
      record.destroy
    end
  end
end
