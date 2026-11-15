# frozen_string_literal: true
class AddOrderCreationEnabledToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :order_creation_disabled, :boolean, default: false
    add_column :site_configs, :order_creation_disabled_tips, :string
  end
end
