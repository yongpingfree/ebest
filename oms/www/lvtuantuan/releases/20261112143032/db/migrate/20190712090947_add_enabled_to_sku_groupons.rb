# frozen_string_literal: true

class AddEnabledToSkuGroupons < ActiveRecord::Migration[5.2]
  def change
    add_column :sku_groupons, :enabled, :boolean, default: true
  end
end
