# frozen_string_literal: true

class SyncAeItemsDeliveryDateEveryDayJob < ApplicationJob
  queue_as :aliexpress

  # 该job执行期间只记录warn以上的日志
  around_perform do |job, block|
    old_level = Rails.logger.level
    Rails.logger.level = Logger::WARN

    block.call
  ensure
    Rails.logger.level = old_level
  end

  def perform
    return unless Rails.env.production?
    
    # 先更新有预计发货时间的产品，日期加1天
    # MagicBean::Item.where(ae_drop_shipper: true, is_ae_choice: true).not_deleted.where.not(ae_delivery_date: nil).find_each do |item|
    #   delivery_date = item.ae_delivery_date.to_date + 1.day
    #   # ae_delivery_date_desc需要判断是否包含-，如果包含-，则后面的日期为delivery_date + 7天
    #   new_ae_delivery_date_desc = delivery_date.strftime("%b. %d"),
      
    #   if item.ae_delivery_date_desc.include?("-")
    #     last_delivery_date = (delivery_date + 7.days).strftime("%b. %d")
    #     new_ae_delivery_date_desc = "#{new_ae_delivery_date_desc} - #{last_delivery_date}"
    #   end
      
    #   item.update_columns(ae_delivery_date_desc: new_ae_delivery_date_desc, ae_delivery_date: delivery_date)
    # end

    MagicBean::Item.where(ae_drop_shipper: true, is_ae_choice: true).not_deleted.where("ae_shipping_info_last_updated_date is null OR ae_shipping_info_last_updated_date < ?", Date.current).includes(:stock_keeping_units).find_each(batch_size: 200) do |item|
      item.update_ae_choice_delivery_date_and_free_shipping_threshold
    end
  end
end
