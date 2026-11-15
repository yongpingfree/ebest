# frozen_string_literal: true

class GenerateCouponsJob < ApplicationJob
  queue_as :coupons

  # admin_user_id只是为了方便后续排查谁生成大量优惠券
  def perform(id, qty, admin_user_id = nil)
    options = {
      id: id,
      qty: qty,
    }

    options = ActiveSupport::JSON.encode(options)
    options = DataEncrypt.aes128_encrypt(options)

    `rake sidekiq:generate_coupons_job[#{options}]`
  end
end
