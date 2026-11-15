# frozen_string_literal: true
class AddThreeHighToStockKeepingUnits < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :height_in_cm, :integer, default: 0
    add_column :stock_keeping_units, :width_in_cm, :integer, default: 0
    add_column :stock_keeping_units, :length_in_cm, :integer, default: 0
    add_column :stock_keeping_units, :barcode, :string
  end
end
