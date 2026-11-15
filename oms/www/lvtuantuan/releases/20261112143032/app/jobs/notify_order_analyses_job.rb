# frozen_string_literal: true

class NotifyOrderAnalysesJob < ApplicationJob
  queue_as :mailers

  def perform
    OrderMailer.order_analyses.deliver_later if Rails.env.production?
  end
end
