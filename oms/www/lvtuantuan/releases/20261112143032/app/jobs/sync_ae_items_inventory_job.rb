# frozen_string_literal: true

class SyncAeItemsInventoryJob < ApplicationJob
  queue_as :aliexpress

  # 该job执行期间只记录warn以上的日志
  around_perform do |job, block|
    old_level = Rails.logger.level
    Rails.logger.level = Logger::WARN

    block.call
  ensure
    Rails.logger.level = old_level
  end

  def perform(item_id = nil, between_ids = [])
    # find_each 会在每个batch执行后进行垃圾回收，默认是1000条数据，这里改为200
    if item_id.present?
      MagicBean::Item.where(ae_drop_shipper: true, id: item_id).not_deleted.find_each do |item|
        item.update_ae_item
      end
    else
      # 生产环境才执行大量同步AE产品的操作
      return unless Rails.env.production?

      # 只同步AE Choice的产品
      if between_ids.present?
        MagicBean::Item.unscoped.where(ae_drop_shipper: true, is_ae_choice: true).not_deleted.where("ae_basic_info_last_updated_date is null OR ae_basic_info_last_updated_date < ?", Date.current).includes(:stock_keeping_units).ransack(id_gteq: between_ids.first || 0, id_lteq: between_ids.last || 0).result.find_each(batch_size: 200) do |item|
          item.update_ae_item
        end
      else
        # 现在有2万多个产品，同步太慢了，改为5个job同时进行同步
        collection = MagicBean::Item.unscoped.where(ae_drop_shipper: true, is_ae_choice: true).not_deleted.where("ae_basic_info_last_updated_date is null OR ae_basic_info_last_updated_date < ?", Date.current).select(:id)
        total_count = collection.count
        batch_size = (total_count / 5.0).ceil
        collection.order(id: :asc).each_slice(batch_size) do |slice_items|
          SyncAeItemsInventoryJob.perform_later(nil, [slice_items.first.id, slice_items.last.id])
        end
      end      
    end
  end
end
