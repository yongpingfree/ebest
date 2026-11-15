# frozen_string_literal: true

class SyncWMSProductJob < ApplicationJob
  queue_as :low_priority

  def perform(item)
      WMSLib.sync_products!(
        item.stock_keeping_units.map do |sku|
          {
            id: sku.id,
            short_title: item.short_title
          }
        end
      )
  end
end
