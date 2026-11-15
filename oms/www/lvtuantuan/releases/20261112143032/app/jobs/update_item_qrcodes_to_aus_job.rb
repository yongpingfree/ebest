# frozen_string_literal: true

class UpdateItemQrcodesToAusJob < ApplicationJob
  queue_as :default

  def perform
    items = MagicBean::Item.where(is_aus_qrcode: false).limit(1500)
    return if items.blank?
    items.each do |item|
      item.send :enqueue_generate_qrcode_job
    end

    UpdateItemQrcodesToAusJob.set(wait_until: 10.minutes.from_now).perform_later
  end
end
