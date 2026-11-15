# frozen_string_literal: true

class AddOrderConfigsToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :order_configs, :json, default: {}
  end
end
