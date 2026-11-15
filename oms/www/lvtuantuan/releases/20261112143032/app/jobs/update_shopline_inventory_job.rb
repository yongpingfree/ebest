# frozen_string_literal: true

class UpdateShoplineInventoryJob < ApplicationJob
  queue_as :shopline

  def perform(sku_id)
    sku = MagicBean::StockKeepingUnit.find(sku_id)

    return unless sku.shopline_synced?

    # 有些商品归档很久，在shopline找不到数据，导致一直同步失败retry, 而商品重现上架会触发更新库存，所以这里跳过下架的商品
    return unless sku.item.online?

    # 出现了shopline sku的third_party_inventory_item_id为空的情况，需要先判断是否为空，为空则更新shopline产品
    # shopline_update_item会触发更新库存
    if sku.shopline_sku.third_party_inventory_item_id.blank?
      sku.item.shopline_update_item(self.class.name, sku_id)
    else
      # 如果是悉尼商品，先写入redis, 再定时批量更新到shopline, peti商品则直接更新
      if sku.peti_store?
        errors_count = Shopline::Api.update_stock(sku.shopline_sku.third_party_inventory_item_id, sku.quantity, sku.peti_store?, sku.delivery_type)

        # 一分钟后重试
        UpdateShoplineInventoryJob.set(wait: 1.minute).perform_later(sku_id) if errors_count.positive?
      else
        Rails.cache.redis.rpush(Shopline::Api::INVENTORY_SKU_REDIS_KEY, sku_id)
      end
    end
  end
end
