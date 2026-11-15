# frozen_string_literal: true

class ChangeStockKeepingUnitsColumnsToFloat < ActiveRecord::Migration[5.2]
  def change
    change_column :stock_keeping_units, :height_in_cm, :float, default: 0
    change_column :stock_keeping_units, :width_in_cm, :float, default: 0
    change_column :stock_keeping_units, :length_in_cm, :float, default: 0
  end
end
