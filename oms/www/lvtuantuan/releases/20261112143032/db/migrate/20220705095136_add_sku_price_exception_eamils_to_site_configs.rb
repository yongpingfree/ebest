# frozen_string_literal: true

class AddSkuPriceExceptionEamilsToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :sku_price_exception_emails, :string, array: true, default: []
  end
end
