# frozen_string_literal: true

class ExportSkuSuppliersJob < ApplicationJob
  queue_as :mailers

  def perform(options)
    `rake mailer:mailer_sku_suppliers_export[#{options}]`
  end
end
