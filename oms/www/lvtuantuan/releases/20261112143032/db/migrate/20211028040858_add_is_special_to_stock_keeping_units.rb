# frozen_string_literal: true

class AddIsSpecialToStockKeepingUnits < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :is_special, :boolean, default: false
  end
end
