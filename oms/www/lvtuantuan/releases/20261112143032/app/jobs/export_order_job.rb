# frozen_string_literal: true

class ExportOrderJob < ApplicationJob
  queue_as :mailers

  def perform(options)
    `rake mailer:mailer_order_export[#{options}]`
  end
end
