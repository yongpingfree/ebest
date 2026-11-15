# frozen_string_literal: true

class AddShoplinePriceRateToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :shopline_price_rate, :decimal, precision: 10, scale: 2, default: 1.2, comment: 'Shopline价格倍率'
  end
end
