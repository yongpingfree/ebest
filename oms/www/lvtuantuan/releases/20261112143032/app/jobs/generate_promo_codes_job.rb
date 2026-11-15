# frozen_string_literal: true

class GeneratePromoCodesJob < ApplicationJob
  queue_as :coupons

  def perform(id, qty)
    options = {
      id: id,
      qty: qty,
    }

    options = ActiveSupport::JSON.encode(options)
    options = DataEncrypt.aes128_encrypt(options)

    `rake sidekiq:generate_promo_codes_job[#{options}]`
  end
end
