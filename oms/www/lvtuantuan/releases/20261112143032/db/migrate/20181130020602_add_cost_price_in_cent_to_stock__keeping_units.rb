# frozen_string_literal: true

class AddCostPriceInCentToStockKeepingUnits < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :cost_price_in_cent, :integer, default: 0
  end
end
