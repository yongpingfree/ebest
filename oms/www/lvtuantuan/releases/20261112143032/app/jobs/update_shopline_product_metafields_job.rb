# frozen_string_literal: true

class UpdateShoplineProductMetafieldsJob < ApplicationJob
  queue_as :shopline

  def perform(item_id, shopline_product_id)
    item = MagicBean::Item.find(item_id)

    res = Shopline::Api.set_product_metafields(item, shopline_product_id)

    # 重试
    UpdateShoplineProductMetafieldsJob.perform_later(item_id, shopline_product_id) if res["errors"].present?
  end
end
