# frozen_string_literal: true

class AddPositionToHotSellConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :hot_sell_configs, :position, :integer, default: 0
  end
end
