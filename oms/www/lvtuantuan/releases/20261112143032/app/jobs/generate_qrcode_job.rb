# frozen_string_literal: true

class GenerateQrcodeJob < ApplicationJob
  queue_as :default

  def perform(type, id, width = 460)
    resource = type.constantize.find_by id: id
    resource.send(:generate_qrcode, width) if resource
  end
end
