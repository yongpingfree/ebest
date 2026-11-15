# frozen_string_literal: true

class AddStrikethroughPriceInCentToStockKeepingUnits < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :strikethrough_price_in_cent, :integer
    remove_column :items, :strikethrough_price, :string
    add_column :items, :strikethrough_price_in_cent, :integer
  end
end
