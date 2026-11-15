# frozen_string_literal: true
class AddCartonSizeToStockKeepingUnits < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :carton_size, :integer, default: 0
  end
end
