# frozen_string_literal: true

class CalculateSkusNominalGrossMarginRatioJob < ApplicationJob
  queue_as :default

  def perform
    MagicBean::StockKeepingUnit.includes(:newest_supplier).ransack(item_ae_drop_shipper_eq: false).result.order(:id).each_slice(200) do |slice_skus|
      slice_skus.each do |sku|
        supplier = sku.newest_supplier
        nominal_gross_margin_ratio = supplier ? (sku.price_in_cent - supplier.cost_in_cent) * 100.0 / sku.price_in_cent : 0
        sku.update_columns nominal_gross_margin_ratio: nominal_gross_margin_ratio
      end
    end
  end
end
