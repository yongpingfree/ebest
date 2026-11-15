# frozen_string_literal: true

class ExportGiftCardJob < ApplicationJob
  queue_as :mailers

  def perform(options)
    `rake mailer:mailer_gift_card_export[#{options}]`
  end
end
