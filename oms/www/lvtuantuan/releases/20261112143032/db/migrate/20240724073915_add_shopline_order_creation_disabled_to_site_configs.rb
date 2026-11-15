# frozen_string_literal: true

class AddShoplineOrderCreationDisabledToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :shopline_order_creation_disabled, :boolean, default: false
  end
end
