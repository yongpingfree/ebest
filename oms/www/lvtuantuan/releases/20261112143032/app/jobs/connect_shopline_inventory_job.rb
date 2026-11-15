# frozen_string_literal: true

class ConnectShoplineInventoryJob < ApplicationJob
  queue_as :shopline

  def perform(inventory_item_id, peti_store)
    errors_count = Shopline::Api.connect_inventory(inventory_item_id, peti_store)
    # 重试
    raise "connect shopline inventory failed" if errors_count.positive?
  end
end
