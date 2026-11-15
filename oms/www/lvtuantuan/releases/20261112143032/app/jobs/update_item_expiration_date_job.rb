# frozen_string_literal: true

class UpdateItemExpirationDateJob < ApplicationJob
  queue_as :default

  def perform
    # 1. 先清空已售罄过批次的商品过期日期
    MagicBean::Item.unscoped.includes(:stock_keeping_units).where(ae_drop_shipper: false).where.not(expiration_date: nil).find_each do |item|
      existence = item.stock_keeping_units.map do |sku|
                    MagicBean::WmsInventory.exists?(["store_id = ? AND product_id = ? AND expiry_date::date = ?", sku.store_id, sku.id, item.expiration_date])
                  end

      next if existence.include?(true)

      item.update_attribute :expiration_date, nil
    end

    # 2. 更新新的过期日期
    today = Date.today
    MagicBean::WmsInventory.not_expired.find_each do |wi|
      item = MagicBean::Item.joins(:stock_keeping_units).where(stock_keeping_units: { store_id: wi.store_id, id: wi.product_id }).first

      next if item.nil?

      new_expiration_date = wi.expiry_date.to_date
      next if item.expiration_date.present? && item.expiration_date.between?(today, new_expiration_date)

      item.update_attribute :expiration_date, new_expiration_date
    end
  end
end
