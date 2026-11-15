# frozen_string_literal: true

class AddStockShortQuantityToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :stock_short_quantity, :integer
  end
end
