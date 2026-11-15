# frozen_string_literal: true

class AddOnSaleToStockKeepingUnits < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :on_sale, :boolean, default: true
  end
end
