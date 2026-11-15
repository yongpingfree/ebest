# frozen_string_literal: true

class ExportSalesPlanJob < ApplicationJob
  queue_as :mailers

  def perform(options)
    `rake mailer:mailer_sales_plan_export[#{options}]`
  end
end
