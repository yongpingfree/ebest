# frozen_string_literal: true

class SyncItemToShoplineJob < ApplicationJob
  queue_as :shopline

  def perform(id)
    item = MagicBean::Item.find(id)

    return unless item.shopline_syncable?

    if item.shopline_synced?
      item.shopline_update_item(self.class.name, id)
    elsif item.channel_match?("shopline")
      # 导入新增多个sku时，会导致重复创建商品，所以先查询是否已经创建
      res = Shopline::Api.products_list(item.peti_store?, "handle=#{URI.encode(item.shopline_handle.gsub(" ", "-"))}")

      # 查询不到数据，会返回{"errors"=>"DATA_NOT_EXIST"}
      # 如果有错误，说明不存在重复产品；否则5秒后重试
      if res["errors"].present?
        item.shopline_create_item
      else
        SyncItemToShoplineJob.set(wait: 5.seconds).perform_later(item.id)
      end
    end
  end
end
