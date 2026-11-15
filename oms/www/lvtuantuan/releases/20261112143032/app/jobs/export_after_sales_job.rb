# frozen_string_literal: true

class ExportAfterSalesJob < ApplicationJob
  queue_as :mailers

  def perform(options)
    `rake mailer:mailer_after_sales_export[#{options}]`
  end
end
