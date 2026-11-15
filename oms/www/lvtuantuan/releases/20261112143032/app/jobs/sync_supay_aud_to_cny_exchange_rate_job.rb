# frozen_string_literal: true

class SyncSupayAudToCnyExchangeRateJob < ApplicationJob
  queue_as :default

  def perform
    Supay::Api.set_rate(MagicBean::Order::SUPAY_WECHAT_KEY)
    Supay::Api.set_rate(MagicBean::Order::SUPAY_ALIPAT_KEY)
  end
end
