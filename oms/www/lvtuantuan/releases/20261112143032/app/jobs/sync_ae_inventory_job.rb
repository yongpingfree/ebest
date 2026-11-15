# frozen_string_literal: true

# 该方法是给AE非跨境购商品同步库存的
class SyncAeInventoryJob < ApplicationJob
  queue_as :aliexpress
  @@aliexpress_logger = ::Logger.new("./log/aliexpress.log")

  def perform
    error_messages = []
    MagicBean::ThirdPartySku.aliexpress.includes(:stock_keeping_unit).each do |ae_sku|
      sku = ae_sku.stock_keeping_unit
      next if sku.nil?
      next if sku.item.ae_item&.third_party_id.nil?

      quantity = sku.quantity / 2 # 向下取整，不需要ceil
      quantity = 0 unless sku.is_on_sale?

      response = MagicBean::StockKeepingUnit.aliexpress_sync_stock(sku, quantity)
      error_messages << {
        no: sku.no,
        error: response
      } if response&.dig("result", "error_message")
    end

    @@aliexpress_logger.error(error_messages) if error_messages.present?
  end
end
