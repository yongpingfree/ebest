# frozen_string_literal: true

class CheckAeItemsDeliveryStatusJob < ApplicationJob
  queue_as :aliexpress

  def perform(item_id)
    item = MagicBean::Item.where(ae_drop_shipper: true, id: item_id).not_deleted.first
    return if item.blank?

    # 该方法会检查商品是否可以发货，如果不能发货，会下架商品
    item.update_ae_choice_delivery_date_and_free_shipping_threshold
  end
end

