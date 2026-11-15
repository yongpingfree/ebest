# frozen_string_literal: true

class UpdateShoplineOrderMetafieldsJob < ApplicationJob
  queue_as :shopline

  def perform(order_no)
    order = MagicBean::ThirdPartyOrder.find_by(no: order_no)

    res = Shopline::Api.set_order_metafields(order, order_no)

    # 重试
    UpdateShoplineOrderMetafieldsJob.perform_later(order_no) if res["errors"].present?
  end
end
