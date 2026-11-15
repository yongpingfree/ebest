# frozen_string_literal: true

class ExportSkuReturnJob < ApplicationJob
  queue_as :mailers

  def perform(options)
    `rake mailer:mailer_sku_return_export[#{options}]`
  end
end
