# frozen_string_literal: true

class AddMerchantDeliveryOrdersLimitEveryDayToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :merchant_delivery_orders_limit_every_day, :integer, default: 0
    rename_column :items, :lastest_presell_dispatch_on, :latest_presell_dispatch_on
  end
end
