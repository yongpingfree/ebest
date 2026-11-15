# frozen_string_literal: true

class UpdateAudToCnyExchangeRateJob < ApplicationJob
  queue_as :default

  def perform
    Omipay::Api.set_rate
  end
end
