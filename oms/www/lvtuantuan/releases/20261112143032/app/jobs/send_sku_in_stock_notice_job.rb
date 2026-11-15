# frozen_string_literal: true

class SendSkuInStockNoticeJob < ApplicationJob
  queue_as :default

  def perform(stock_keeping_unit_id)
    return unless stock_keeping_unit = MagicBean::StockKeepingUnit.find_by(id: stock_keeping_unit_id)

    ApplicationRecord.transaction do
      Sidekiq.redis do |redis|
        redis.multi do
          stock_keeping_unit.sku_in_stock_notices.pending.find_each do |sku_in_stock_notice|
            sku_in_stock_notice.notice! if sku_in_stock_notice.may_notice?
          end
        end
      end
    end
  end
end
