# frozen_string_literal: true

class RecordSkuValidInventoryEveryDayJob < ApplicationJob
  queue_as :default

  def perform
    MagicBean::Item.where(ae_drop_shipper: false).on_sale_with_stock.includes([:on_sale_skus]).find_each do |item|
      item.send :set_sku_valid_inventory_dates
    end
  end
end
