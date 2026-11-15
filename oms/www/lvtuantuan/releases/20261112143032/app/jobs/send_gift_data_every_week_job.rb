# frozen_string_literal: true

class SendGiftDataEveryWeekJob < ApplicationJob
  queue_as :default

  def perform
    OrderMailer.week_gift_data.deliver
  end
end
