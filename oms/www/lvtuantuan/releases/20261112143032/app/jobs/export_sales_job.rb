# frozen_string_literal: true

class ExportSalesJob < ApplicationJob
  queue_as :mailers

  def perform(options)
    `rake mailer:mailer_sales_export[#{options}]`
  end
end
