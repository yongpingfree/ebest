# frozen_string_literal: true

class SendKlaviyoEmailJob < ApplicationJob
  queue_as :deliver_sms

  def perform(model_name, id, method)
    return if Rails.env.test? || Rails.env.development?

    record = model_name.constantize.find_by id: id
    return if record.nil?

    begin
      record.send method
    rescue KlaviyoAPI::ApiError
      # Ignore: 有些用户会填写错误的邮箱地址（例如：abc@gmail，没有 .com 后缀），导致发送失败
    end
  end
end
