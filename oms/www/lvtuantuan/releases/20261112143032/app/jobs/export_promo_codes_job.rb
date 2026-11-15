# frozen_string_literal: true

class ExportPromoCodesJob < ApplicationJob
  queue_as :mailers

  def perform(options)
    `rake mailer:mailer_promo_codes_export[#{options}]`
  end
end
