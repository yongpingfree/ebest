# frozen_string_literal: true

class CreateShoplineOrderJob < ApplicationJob
  queue_as :shopline

  def perform(shopline_order_no, peti_store, store_site_config_id)
    store_site_config = MagicBean::SiteConfig.find(store_site_config_id)

    MagicBean::ThirdPartyOrder.create_shopline_order(shopline_order_no, peti_store, store_site_config)
  end
end
