# frozen_string_literal: true

class ExportSkuInStockNoticeJob < ApplicationJob
  queue_as :mailers

  def perform(options)
    `rake mailer:mailer_sku_in_stock_notice_export[#{options}]`
  end
end
